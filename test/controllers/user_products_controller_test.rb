require 'test_helper'

class UserProductsControllerTest < ActionController::TestCase
  setup do
    @user1 = users(:user1)
    @user2 = users(:user2)
    @user3 = users(:user3)

    @product1 = products(:product1)
    @product2 = products(:product2)
    @product3 = products(:keyword_search1)

    @shelf_user_product1 = user_products(:shelf_user_product1)
    @ignore_user_product1 = user_products(:ignore_user_product1)

    UserProduct.all.each {|user_product| user_product.send(:save_to_fts) }
  end

  teardown do
    Groonga['UserProducts'].each { |record| record.delete }
  end

  test "タグ付け済みの商品一覧を返す" do
    get :show, {:id => @user3.id}, {:user_id => @user3.id}
    assert_response :success
    assert_equal 1, assigns(:user_products).size
    assert_equal @shelf_user_product1, assigns(:user_products).first
  end

  test "プライベートユーザのタグ付け済み商品一覧をゲストは表示できない" do
    get :show, {:id => @user3.id}
    assert_response :forbidden
  end

  test "プライベートユーザのタグ付け済み商品一覧を他のユーザは表示できない" do
    get :show, {:id => @user3.id}, {:user_id => @user1.id}
    assert_response :forbidden
  end

  test "公開ユーザのタグ付け済み商品一覧をゲストは表示できる" do
    get :show, {:id => @user1.id}
    assert_response :success
  end

  test "公開ユーザのタグ付け済み商品一覧を他のユーザは表示できる" do
    get :show, {:id => @user1.id}, {:user_id => @user2.id}
    assert_response :success
  end

  test "タグ付け済みの商品を検索できる" do
    get :show,
      {:id => @user2.id, :keyword => 'search1'},
      {:user_id => @user2.id}
    assert_response :success
    assert_equal 1, assigns(:user_products).size
    assert_equal user_products(:user_product2), assigns(:user_products).first
  end

  test "商品に対してタグ付けできる" do
    assert_difference('UserProduct.count') do
      post :create,
        {:product_id => @product3.id, :type_name => 'shelf', :tags => '["tag1", "tag2"]', :format => :json},
        {:user_id => @user3.id}
    end
    assert_response :success
    assert_equal @product3, assigns(:user_product).product
    assert_equal ['tag1', 'tag2'], assigns(:user_product).tags
  end

  test "タグ付け済みの商品に対してタグの更新ができる。アクションは新規生成と共通" do
    assert_no_difference('UserProduct.count') do
      post :create,
        {:product_id => @shelf_user_product1.product.id, :type_name => 'shelf', :tags => '["tag1", "tag2"]', :format => :json},
        {:user_id => @user3.id}
    end
    assert_response :success
    assert_equal ['tag1', 'tag2'], assigns(:user_product).tags
  end

  test "タグ付け済みの商品を削除できる" do
    assert_difference('UserProduct.count', -1) do
      delete :destroy,
        {:id => @shelf_user_product1.id, :type_name => 'shelf', :format => :json},
        {:user_id => @user3.id}
    end
    assert_response :success
  end

  test "商品の無視指定ができる" do
    assert_no_difference('UserProduct.count') do
      post :create,
        {:product_id => @product1.id, :type_name => 'ignore', :format => :json},
        {:user_id => @user3.id}
    end
    assert_response :success
    assert_equal @product1, assigns(:user_product).product
    assert_equal 'ignore', assigns(:user_product).type_name
  end

  test "無視指定済みの商品を再度無視指定できない" do
    assert_no_difference('UserProduct.count') do
      post :create,
        {:product_id => @product2.id, :type_name => 'ignore', :format => :json},
        {:user_id => @user3.id}
    end
    assert_response 400
  end

  test "無視指定を解除できる" do
    assert_no_difference('UserProduct.count') do
      delete :destroy,
        {:id => @ignore_user_product1.id, :type_name => 'ignore', :format => :json},
        {:user_id => @user3.id}
    end
    assert_response :success
    assert_equal 'search', assigns(:user_product).type_name
  end
end
