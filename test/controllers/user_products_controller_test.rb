require 'test_helper'

class UserProductsControllerTest < ActionController::TestCase
  setup do
    @user1 = users(:user1)
    @user2 = users(:user2)
    
    @product1 = products(:product1)
    @user_product1 = user_products(:user_product1)
  end
  
  test "タグ付け済みの商品一覧を返す" do
    get :show, 
      {:id => @user1.id}
    assert_response :success
  end
  
  test "タグ付け済みの商品を検索できる" do
    get :show, 
      {:id => @user1.id, :keyword => 'keyword1'}
    assert_response :success
  end
  
  test "商品に対してタグ付けできる" do
    assert_difference('UserProduct.count') do
      post :create, 
        {:product_id => @product1.id, :tags => '[tag1][tag2]', :format => :json},
        {:user_id => @user1.id}
    end
    assert_response :success
    assert_equal @product, assigns(:user_product).product
    assert_equal ['tag1', 'tag2'], assigns(:user_product).tags
  end
  
  test "タグ付け済みの商品に対してタグの更新ができる" do
    assert_no_difference('UserProduct.count') do
      put :update,
        {:id => @user_product1.id, :tags => '[tag1][tag2]', :format => :json},
        {:user_id => @user1.id}
    end
    assert_response :success
    assert_equal ['tag1', 'tag2'], assigns(:user_product).tags
  end
  
  test "タグ付け済みの商品を削除できる" do
    assert_difference('UserProduct.count', -1) do
      delete :destroy,
        {:id => @user_product1.id, :format => :json},
        {:user_id => @user1.id}
    end
    assert_response :success
  end
  
  test "商品の無視指定ができる" do
    assert_difference('UserProduct.count') do
      post :create, 
        {:product_id => @product1.id, :type_name => 'ignore', :format => :json},
        {:user_id => @user1.id}
    end
    assert_response :success
    assert_equal @product, assigns(:user_product).product
    assert_equal 'ignore', assigns(:user_product).type_name
  end
  
  test "無視指定を解除できる" do
    assert_difference('UserProduct.count') do
      post :create, 
        {:product_id => @product1.id, :type_name => 'ignore'},
        {:user_id => @user1.id}
    end
    assert_response :success
    assert_equal @product, assigns(:user_product).product
    assert_equal 'ignore', assigns(:user_product).type_name
  end
end
