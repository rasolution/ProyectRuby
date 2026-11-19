require 'test_helper'

class RepairsTest < ActionDispatch::IntegrationTest
  setup { sign_in_test_user }

  test 'both products must exist before an exchange is saved' do
    [[products(:one).id, 999_999_999], [999_999_999, products(:two).id], [nil, nil]].each do |offered, requested|
      assert_no_difference('Transaction.count') do
        post '/transactions.json', params: {transaction: {offert_product_id: offered, require_product_id: requested}}, headers: @headers, as: :json
      end
      assert_response :unprocessable_entity
    end
  end

  test 'self exchange and duplicate normalized pairs are rejected' do
    [[products(:one).id, products(:one).id], [products(:one).id, "000#{products(:two).id}"]].each do |offered, requested|
      post '/transactions.json', params: {transaction: {offert_product_id: offered, require_product_id: requested}}, headers: @headers, as: :json
      assert_response :unprocessable_entity
    end
  end

  test 'invalid exchange update does not partially change a saved pair' do
    row = transactions(:one); original = row.attributes.slice('offert_product_id', 'require_product_id')
    patch "/transactions/#{row.id}.json", params: {transaction: {offert_product_id: products(:two).id, require_product_id: 'invalid'}}, headers: @headers, as: :json
    assert_response :unprocessable_entity
    assert_equal original, row.reload.attributes.slice('offert_product_id', 'require_product_id')
  end

  test 'a referenced product cannot be deleted out from under an exchange' do
    row = products(:one)
    assert_no_difference('Product.count') { delete "/products/#{row.id}.json", headers: @headers }
    assert_response :conflict
    assert Transaction.exists?(transactions(:one).id)
  end

  test 'negative fractional and empty product inputs return 422' do
    [{name: ' '}, {price: -1}, {price: '1.75'}, {state: 'invalid'}, {state: -1}].each do |invalid|
      assert_no_difference('Product.count') do
        post '/products.json', params: {product: {name: 'Producto', price: 1, state: 1}.merge(invalid)}, headers: @headers, as: :json
      end
      assert_response :unprocessable_entity
    end
  end

  test 'invalid product edit preserves the stored values' do
    row = products(:one); old = row.attributes.slice('name', 'price')
    patch "/products/#{row.id}.json", params: {product: {name: 'No guardar', price: '-2'}}, headers: @headers, as: :json
    assert_response :unprocessable_entity
    assert_equal old, row.reload.attributes.slice('name', 'price')
  end

  test 'missing and malformed IDs return controlled 404 JSON' do
    ["/products/#{products(:one).id}oops.json", '/products/999999999.json', '/transactions/invalid.json', '/users/not-a-number.json'].each do |path|
      get path, headers: @headers
      assert_response :not_found
      assert_equal 'El registro no existe.', response.parsed_body['error']
    end
  end

  test 'expired or orphaned tokens are rejected' do
    ApiKey.find_by!(access_token: @token).update_columns(current: 25.hours.ago)
    get '/products.json', headers: @headers; assert_response :unauthorized
    key = ApiKey.create!(username: 'missing-user', current: Time.current)
    get '/products.json', headers: {'Authorization' => key.access_token}; assert_response :unauthorized
  end

  test 'login rotates the previous token and raw authorization remains compatible' do
    old = @token
    post '/login', params: {user: {username: @actor.username, password: 'Valid-test-password'}}, as: :json
    assert_response :success
    fresh = response.parsed_body['auth_token']; assert_not_equal old, fresh
    assert_equal 'no-store', response.headers['Cache-Control']
    get '/products.json', headers: {'Authorization' => old}; assert_response :unauthorized
    get '/products.json', headers: {'Authorization' => fresh}; assert_response :success
  end

  test 'a proven legacy MD5 password upgrades to bcrypt without changing the account' do
    now = Time.current; hash = Digest::MD5.hexdigest('old-key')
    User.insert_all!([{username: 'legacy-user', password: hash, created_at: now, updated_at: now}])
    user = User.find_by!(username: 'legacy-user')
    post '/login', params: {user: {username: user.username, password: 'wrong'}}, as: :json
    assert_response :unauthorized; assert_nil user.reload.password_digest; assert_equal hash, user[:password]
    post '/login', params: {user: {username: user.username, password: 'old-key'}}, as: :json
    assert_response :success; user.reload
    assert user.authenticate('old-key'); assert_nil user[:password]; assert_match(/\A\$2/, user.password_digest)
  end

  test 'oversized legacy passwords remain usable and are never silently truncated' do
    password = 'x' * 80; now = Time.current
    User.insert_all!([{username: 'legacy-long', password: Digest::MD5.hexdigest(password), created_at: now, updated_at: now}])
    post '/login', params: {user: {username: 'legacy-long', password: password}}, as: :json
    assert_response :success; assert_nil User.find_by!(username: 'legacy-long').password_digest
    post '/login', params: {user: {username: 'legacy-long', password: password[0,72]}}, as: :json
    assert_response :unauthorized
  end

  test 'bcrypt login rejects oversized candidates instead of truncating them' do
    password = 'x' * 72
    user = User.create!(username: 'bcrypt-boundary', password: password)
    digest = user.password_digest
    post '/login', params: {user: {username: user.username, password: password}}, as: :json
    assert_response :success
    post '/login', params: {user: {username: user.username, password: password + 'suffix'}}, as: :json
    assert_response :unauthorized
    assert_equal digest, user.reload.password_digest
  end

  test 'an account cannot read edit or delete another identity' do
    other = users(:one)
    get "/users/#{other.id}.json", headers: @headers; assert_response :not_found
    patch "/users/#{other.id}.json", params: {user: {password: 'Unwanted-password'}}, headers: @headers, as: :json; assert_response :not_found
    assert_no_difference('User.count') { delete "/users/#{other.id}.json", headers: @headers }
    assert_response :not_found
  end

  test 'invalid password challenges and multibyte oversized passwords preserve credentials' do
    digest = @actor.password_digest
    [{password: 'New-password', password_challenge: 'wrong'},
     {password: 'é' * 37, password_challenge: 'Valid-test-password'},
     {password: 42, password_challenge: 'Valid-test-password'},
     {password: "bad\0password", password_challenge: 'Valid-test-password'}].each do |data|
      patch "/users/#{@actor.id}.json", params: {user: data}, headers: @headers, as: :json
      assert_response :unprocessable_entity; assert_equal digest, @actor.reload.password_digest
    end
    assert ApiKey.exists?(access_token: @token)
  end

  test 'account responses omit passwords digests and caller-supplied tokens' do
    @actor.update_columns(token: 'sensitive-legacy-marker')
    get '/users.json', headers: @headers; assert_response :success
    assert_not_includes response.body, 'sensitive-legacy-marker'
    assert_empty response.parsed_body.first.keys & %w[password password_digest token]
    get "/users/#{@actor.id}", headers: @headers
    assert_response :success; assert_not_includes response.body, 'sensitive-legacy-marker'
    patch "/users/#{@actor.id}.json", params: {user: {token: 'caller-forged'}}, headers: @headers, as: :json
    assert_response :success; assert_equal 'sensitive-legacy-marker', @actor.reload.token
  end

  test 'missing request bodies do not become server errors' do
    post '/login', params: {}, as: :json; assert_response :bad_request
    post '/products.json', params: {}, headers: @headers, as: :json; assert_response :bad_request
  end
end
