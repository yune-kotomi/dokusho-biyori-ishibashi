require 'test_helper'

class KeywordsControllerTest < ActionController::TestCase
  setup do
    @keyword1 = keywords(:keyword1)
    @keyword2 = keywords(:keyword2)

    @user_keyword1 = user_keywords(:user_keyword1)
    @user_keyword1_2 = user_keywords(:user_keyword1_2)

    @user1 = users(:user1)
    @user2 = users(:user2)
  end

  test "ゲストは表示できない" do
    get :index
    assert_response :forbidden
  end

  test "ユーザは自分の持っているキーワードを表示できる" do
    get :index, {}, {:user_id => @user1.id}
    assert_response :success
    assert_equal @keyword1, assigns(:user_keywords).first.keyword
  end

  test "新しいキーワードを追加するとkeywordとuser_keywordを生成する" do
    assert_difference('Keyword.count') do
      assert_difference('UserKeyword.count') do
        post :create,
          {:keyword => {:value => 'キーワード', :category => 'books'}, :format => :json},
          :user_id => @user1.id
      end
    end
    assert_response :success
  end

  test "既存のキーワードを追加するとuser_keywordを生成する" do
    assert_no_difference('Keyword.count') do
      assert_difference('UserKeyword.count') do
        post :create,
          {:keyword => {:value => @keyword1.value, :category => 'books'}, :format => :json},
          :user_id => @user2.id
      end
    end
    assert_response :success
  end

  test "登録済みのキーワードは追加できない" do
    assert_no_difference('Keyword.count') do
      assert_no_difference('UserKeyword.count') do
        post :create,
          {
            :keyword => {:value => @keyword1.value, :category => @keyword1.category},
            :format => :json
          },
          :user_id => @user1.id
      end
    end
    assert_response :forbidden
  end

  test "自分のキーワードは削除可能" do
    assert_difference('Keyword.count', -1) do
      assert_difference('UserKeyword.count', -1) do
        delete :destroy,
          {:id => @user_keyword1.id, :format => :json},
          {:user_id => @user1.id}
      end
    end
    assert_response :success
  end

  test "全員がキーワードを削除するまでKeywordは残す" do
    assert_no_difference('Keyword.count') do
      assert_difference('UserKeyword.count', -1) do
        delete :destroy,
          {:id => @user_keyword1_2.id, :format => :json},
          {:user_id => @user1.id}
      end
    end
    assert_response :success
  end

  test "持っていないキーワードは削除不可" do
    assert_no_difference('Keyword.count') do
      assert_no_difference('UserKeyword.count') do
        delete :destroy,
          {:id => @user_keyword1.id, :format => :json},
          {:user_id => @user2.id}
      end
    end
    assert_response :missing
  end
end
