require 'test_helper'
class WelcomeControllerTest < ActionDispatch::IntegrationTest
  test 'the local application entry is available without a token' do
    get '/'; assert_response :success
  end
end
