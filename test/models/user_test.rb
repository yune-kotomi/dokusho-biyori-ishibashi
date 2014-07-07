require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    @public_user = users(:user1)
    @private_user = users(:user2) # 非公開、秘匿キー設定なし
    @limited_user = users(:user3) # 非公開、秘匿キー設定あり

    UserProduct.all.each {|user_product| user_product.send(:save_to_fts) }
  end
  
  test "公開ユーザを非公開状態、秘匿URL有効に書き換えたら秘匿キーを生成して保存" do
    @public_user.update_attributes(:private => true, :random_url => true)
    assert @public_user.random_key.present?
  end
  
  test "非公開ユーザを秘匿URL有効に書き換えたら秘匿キーを生成して保存" do
    @private_user.update_attribute(:random_url, true)
    assert @private_user.random_key.present?
  end
  
  test "非公開ユーザを公開状態に書き換えたら秘匿キーをクリア" do
    @limited_user.update_attribute(:private, false)
    assert_equal false, @limited_user.random_url
    assert @limited_user.random_key.blank?
  end
  
  test "秘匿キー設定済みユーザを秘匿URL無効に書き換えたら秘匿キーをクリア" do
    @limited_user.update_attribute(:random_url, false)
    assert @limited_user.random_key.blank?
  end
  
  test "秘匿URL有効の場合、別のアトリビュートを更新しても秘匿キーは変化なし" do
    previous_key = @limited_user.random_key
    @limited_user.update_attribute(:nickname, 'test')
    assert_equal previous_key, @limited_user.random_key
  end
  
  test "tagsは{タグ文字列=>総数}の形式で返される" do
    @public_user.tags.each do |key, value|
      assert_equal String, key.class
      assert_equal Integer, value.class
    end
  end
  
  test "tagsはjsonとして保存する" do
    source = {'a' => 3, 'b' => 2}
    @public_user.update_attributes(:tags => source)
    @public_user.reload
    assert_equal source.to_json, @public_user.attributes['tags']
  end
  
  test "タグの追加・削除がupdate_tagsで行える" do
    @public_user.update_tags(['tag1', 'tag2'], ['tag3'])
    assert_equal ({'tag1' => 1, 'tag2' => 1}), @public_user.tags
    
    @public_user.update_tags(['tag1', 'tag3'], ['tag2'])
    assert_equal ({'tag1' => 2, 'tag3' => 1}), @public_user.tags
    
    @public_user.update_tags(['tag2'], ['tag1'])
    assert_equal ({'tag1' => 1, 'tag2' => 1, 'tag3' => 1}), @public_user.tags
  end
  
  test "#search_user_productは指定されたキーワードでUserProductを検索して返す" do
    user_products = @private_user.search_user_products('search1')
    assert_equal 1, user_products.size
    assert_equal user_products(:user_product2), user_products.first
  end
end

