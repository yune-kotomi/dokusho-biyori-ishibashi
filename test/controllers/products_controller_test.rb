require 'test_helper'

class ProductsControllerTest < ActionController::TestCase
  setup do
    @product = products(:keyword_search1)
    @products = [
      products(:keyword_search2),
      products(:product1)
    ]
  end

  test "should show product" do
    get :show, id: @product.ean
    assert_response :success
    assert_equal @product, assigns(:product)
  end

  test '複数商品表示' do
    get :show, :id => @product.ean, :ean => @products.map(&:ean)
    assert_response :success
    assert_equal @product, assigns(:product)
    assert_equal @products, assigns(:products)
  end

  test "Amazonへのリダイレクト" do
    get :to_amazon, :id => @product.ean
    assert_response :redirect
    assert @response.header['Location'] == @product.a_url
  end

  test "楽天ブックスへのリダイレクト" do
    get :to_rakuten, :id => @product.ean
    assert_response :redirect
    assert @response.header['Location'] == @product.r_url
  end
end
