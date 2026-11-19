require "test_helper"

class LocalSmokeTest < ActionDispatch::IntegrationTest
  test "health and authenticated catalog CRUD" do
    get "/up"
    assert_response :success
    get "/products.json"
    assert_response :unauthorized

    user = User.create!(username: "smoke-local", password: "prueba-local")
    post "/login", params: { user: { username: user.username, password: "prueba-local" } }, as: :json
    assert_response :success
    token = response.parsed_body.fetch("auth_token")
    headers = { "Authorization" => token }
    assert_equal user.username, ApiKey.find_by!(access_token: token).username

    post "/products.json", params: { product: { name: "Café", price: 15, state: 1 } }, headers: headers, as: :json
    assert_response :created
    id = response.parsed_body.fetch("id")
    patch "/products/#{id}.json", params: { product: { price: 22 } }, headers: headers, as: :json
    assert_response :success
    assert_equal 22, Product.find(id).price
    delete "/products/#{id}.json", headers: headers, as: :json
    assert_response :no_content
    assert_not Product.exists?(id)
    get "/logout", headers: headers, as: :json
    assert_response :success
    get "/products.json", headers: headers
    assert_response :unauthorized
  end

  test "credentials from another user do not reuse the first users token" do
    first = User.create!(username: "smoke-first", password: "first-secret")
    second = User.create!(username: "smoke-second", password: "second-secret")
    post "/login", params: { user: { username: first.username, password: "first-secret" } }, as: :json
    first_token = response.parsed_body.fetch("auth_token")
    post "/login", params: { user: { username: second.username, password: "second-secret" } }, as: :json
    second_token = response.parsed_body.fetch("auth_token")
    assert_not_equal first_token, second_token
    assert_equal second.username, ApiKey.find_by!(access_token: second_token).username
  end
end
