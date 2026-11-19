require 'test_helper'
class TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_test_user; @exchange = transactions(:one) }
  test('index') { get '/transactions.json', headers: @headers; assert_response :success; assert response.parsed_body.any? { |r| r['id'] == @exchange.id } }
  test('new form') { get '/transactions/new', headers: @headers; assert_response :success }
  test 'create exchange' do
    product = Product.create!(name: 'Nuevo', price: 5, state: 1)
    assert_difference('Transaction.count') { post '/transactions.json', params: {transaction: {offert_product_id: products(:one).id, require_product_id: product.id}}, headers: @headers, as: :json }
    assert_response :created
  end
  test('show') { get "/transactions/#{@exchange.id}.json", headers: @headers; assert_response :success; assert_equal @exchange.id, response.parsed_body['id'] }
  test('edit form') { get "/transactions/#{@exchange.id}/edit", headers: @headers; assert_response :success }
  test 'update exchange' do
    product = Product.create!(name: 'Otro', price: 5, state: 1)
    patch "/transactions/#{@exchange.id}.json", params: {transaction: {require_product_id: product.id}}, headers: @headers, as: :json
    assert_response :success; assert_equal product.id.to_s, @exchange.reload.require_product_id
  end
  test('destroy') { assert_difference('Transaction.count', -1) { delete "/transactions/#{@exchange.id}.json", headers: @headers }; assert_response :no_content }
end
