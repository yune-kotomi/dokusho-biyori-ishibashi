require 'test_helper'

class UserProductTest < ActiveSupport::TestCase
  setup do
    @user = users(:user1)
    @product = products(:keyword_search2)
    @user_product = user_products(:user_product1)

    @groonga = Groonga['UserProducts']
    UserProduct.all.each {|user_product| user_product.send(:save_to_fts) }
  end

  teardown do
    @groonga.each { |record| record.delete }
  end

  test "tagsは配列でタグ一覧を返す" do
    assert @user_product.tags.is_a?(Array)
  end

  test "tags=にタグ一覧を与えるとJSONとして格納される" do
    tags = ['tag1', 'tag2']
    @user_product.tags = tags
    assert_equal tags.to_json, @user_product.tags_json
  end

  test "作成時にgroongaのインデックスを更新する" do
    assert_difference "@groonga.size" do
      user_product = @user.user_products.create(:product_id => @product.id)
    end
  end

  test "編集時にgroongaのインデックスを更新する" do
    assert_no_difference "@groonga.size" do
      @user_product.tags = ['tag1', 'tag2']
      @user_product.save
    end
    assert_equal 1, @groonga.select {|r| r.text =~ '[tag1]' }.size
  end

  test "削除時にgroongaのインデックスからも削除する" do
    assert_difference "@groonga.size", -1 do
      @user_product.destroy
    end
  end

  test "作成時、ユーザのタグ一覧を更新する" do
    assert_difference '@user.tag_table["tag1"].to_i' do
      user_product = @user.user_products.create(:product_id => @product.id, :type_name => 'shelf', :tags => ['tag1'])
      @user.reload
    end
  end

  test "編集時にユーザのタグ一覧を更新する" do
    assert_difference '@user.tag_table["tag1"].to_i' do
      @user_product.tags = ['tag1']
      @user_product.save
      @user.reload
    end
  end

  test "削除時にユーザのタグ一覧を更新する" do
    @user_product.tags = ['tag1']
    @user_product.save
    @user.reload

    assert_difference '@user.tag_table["tag1"].to_i', -1 do
      @user_product.tags = []
      @user_product.save
      @user.reload
    end
  end
end
