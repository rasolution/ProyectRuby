require 'test_helper'
class UsersControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_test_user }
  test('index contains only current identity') { get '/users.json', headers: @headers; assert_response :success; assert_equal [@actor.id], response.parsed_body.map { |u| u['id'] } }
  test('new form') { get '/users/new', headers: @headers; assert_response :success; assert_select 'input[type=password]' }
  test 'create account without accepting a caller token' do
    assert_difference('User.count') { post '/users.json', params: {user: {username: 'new-account', password: 'Strong-new-password', token: 'forged'}}, headers: @headers, as: :json }
    assert_response :created; assert_nil User.find(response.parsed_body['id']).token
    assert_equal %w[created_at id updated_at username], response.parsed_body.keys.sort
  end
  test('show') { get "/users/#{@actor.id}.json", headers: @headers; assert_response :success; assert_equal @actor.username, response.parsed_body['username'] }
  test('edit form') { get "/users/#{@actor.id}/edit", headers: @headers; assert_response :success; assert_select 'input[name="user[token]"]', count: 0 }
  test 'password update requires the old password and revokes sessions' do
    patch "/users/#{@actor.id}.json", params: {user: {password: 'Replacement-password', password_challenge: 'Valid-test-password'}}, headers: @headers, as: :json
    assert_response :success; assert @actor.reload.authenticate('Replacement-password'); assert_not ApiKey.exists?(access_token: @token)
  end
  test 'destroy own account revokes its token' do
    assert_difference('User.count', -1) { delete "/users/#{@actor.id}.json", headers: @headers }
    assert_response :no_content; assert_not ApiKey.exists?(access_token: @token)
  end
end
