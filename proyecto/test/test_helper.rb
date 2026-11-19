ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

ActiveModel::SecurePassword.min_cost = true
module AuthenticatedRequests
  def sign_in_test_user
    @actor = User.create!(username: "test-#{SecureRandom.hex(6)}", password: 'Valid-test-password')
    post '/login', params: { user: { username: @actor.username, password: 'Valid-test-password' } }, as: :json
    assert_response :success
    @token = response.parsed_body.fetch('auth_token')
    @headers = { 'Authorization' => "Bearer #{@token}" }
  end
end
ActionDispatch::IntegrationTest.include AuthenticatedRequests
