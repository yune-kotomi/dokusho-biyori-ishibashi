require 'test_helper'

class ProductsControllerTest < ActionController::TestCase
  setup do
    @product = products(:keyword_search1)
  end

  test "should show product" do
    get :show, id: @product
    assert_response :success
  end
end
