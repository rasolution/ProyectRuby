require 'test_helper'
class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_test_user; @product = products(:one) }
  test('index') { get '/products.json', headers: @headers; assert_response :success; assert response.parsed_body.any? { |p| p['id'] == @product.id } }
  test('new form') { get '/products/new', headers: @headers; assert_response :success; assert_select 'form' }
  test 'create product' do
    assert_difference('Product.count') { post '/products.json', params: {product: {name: 'Café', price: 15, state: 1}}, headers: @headers, as: :json }
    assert_response :created
  end
  test('show') { get "/products/#{@product.id}.json", headers: @headers; assert_response :success; assert_equal @product.name, response.parsed_body['name'] }
  test('edit form') { get "/products/#{@product.id}/edit", headers: @headers; assert_response :success; assert_select 'form' }
  test 'update product' do
    patch "/products/#{@product.id}.json", params: {product: {name: 'Actualizado', price: 20}}, headers: @headers, as: :json
    assert_response :success; assert_equal 'Actualizado', @product.reload.name
  end
  test 'destroy unreferenced product' do
    free = Product.create!(name: 'Libre', price: 1, state: 0)
    assert_difference('Product.count', -1) { delete "/products/#{free.id}.json", headers: @headers }
    assert_response :no_content
  end
end
