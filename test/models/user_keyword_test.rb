require 'test_helper'

class UserKeywordTest < ActiveSupport::TestCase
  setup do
    @keyword = keywords(:keyword2)
    @user = users(:user4)
    @user_keyword = user_keywords(:user_keyword_5_2)
    @user1 = users(:user5)
  end

  test "新規作成時に対応するキーワード・ユーザのUserProductを生成する" do
    assert_difference "UserProduct.count", @keyword.keyword_products.count do
      assert_difference "UserKeyword.count" do
        @user.user_keywords.create(:keyword_id => @keyword.id)
      end
    end

    assert_equal @keyword.keyword_products.map{|kp| kp.product_id }.sort, @user.user_products.map{|up| up.product_id }.sort
  end

  test "削除時に対応するUserProductを削除する" do
    # 複数のキーワードから登録される商品は次回のクロールで復元されるので気にしない
    assert_difference "UserProduct.count", @keyword.keyword_products.count * -1 do
      assert_difference "UserKeyword.count", -1 do
        @user_keyword.destroy
      end
    end
  end
end
