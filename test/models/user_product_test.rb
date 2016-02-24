require 'test_helper'

class UserProductTest < ActiveSupport::TestCase
  setup do
    @user = users(:user1)
    @product = products(:keyword_search2)
    @user_product = user_products(:user_product1)
  end

  test "作成時、ユーザのタグ一覧を更新する" do
    assert_difference '@user.tags["tag1"].to_i' do
      user_product = @user.user_products.create(:product_id => @product.id, :type_name => 'shelf', :tags => ['tag1'])
      @user.reload
    end
  end

  test "編集時にユーザのタグ一覧を更新する" do
    assert_difference '@user.tags["tag1"].to_i' do
      @user_product.tags = ['tag1']
      @user_product.save
      @user.reload
    end
  end

  test "削除時にユーザのタグ一覧を更新する" do
    @user_product.tags = ['tag1']
    @user_product.save
    @user.reload

    assert_difference '@user.tags["tag1"].to_i', -1 do
      @user_product.tags = []
      @user_product.save
      @user.reload
    end
  end
end
