# coding: utf-8
require 'test_helper'
require 'rss'

class UsersControllerTest < ActionController::TestCase
  setup do
    WebMock.reset!
    @user1 = users(:user1)
    @user2 = users(:user2)
    @user3 = users(:user3)
  end

  test "loginは認証サービスへリダイレクトする" do
    get :login
    assert_response :redirect

    uri = URI @response.header['Location']
    params = CGI.parse uri.query

    assert_equal Ishibashi::Application.config.authentication.service_id,
      params['id'].first.to_i
    assert params['token'].first.present?
  end

  test "login_completeは認証情報を取得し、問題なければユーザを生成する" do
    new_user = {
      :profile_id => 0,
      :domain_name => 'www.example.com',
      :screen_name => 'screen_name',
      :nickname => 'nickname',
      :profile_text => 'profile',
      :openid_url => 'http://www.example.com/screen_name',
      :exp => 5.minutes.from_now.to_i
    }

    WebMock.stub_request(:get, /#{Ishibashi::Application.config.authentication.entry_point}\/retrieve\?.*/).to_return(
      :body => JWT.encode(new_user, Ishibashi::Application.config.authentication.key)
    )

    payload = {'key' => 'auth key', 'exp' => 5.minutes.from_now.to_i}
    token = JWT.encode(payload, Ishibashi::Application.config.authentication.key)
    assert_difference 'User.count' do
      get :login_complete,
        :id => Ishibashi::Application.config.authentication.service_id,
        :token => token
    end
    assert_redirected_to :controller => :users,
      :action => :show,
      :domain_name => new_user[:domain_name],
      :screen_name => new_user[:screen_name]
    assert_not_nil assigns(:user)
    assert_equal assigns(:user).id, session[:user_id]
  end

  test "login_completeは既存ユーザをログインさせる" do
    new_user = {
      :profile_id => @user1.kitaguchi_profile_id,
      :domain_name => @user1.domain_name,
      :screen_name => @user1.screen_name,
      :nickname => @user1.nickname,
      :profile_text => @user1.profile_text,
      :openid_url => 'http://example.com/screen_name',
      :exp => 5.minutes.from_now.to_i
    }

    WebMock.stub_request(:get, /#{Ishibashi::Application.config.authentication.entry_point}\/retrieve\?.*/).to_return(
      :body => JWT.encode(new_user, Ishibashi::Application.config.authentication.key)
    )

    payload = {'key' => 'auth key', 'exp' => 5.minutes.from_now.to_i}
    token = JWT.encode(payload, Ishibashi::Application.config.authentication.key)
    assert_no_difference  'User.count' do
      get :login_complete,
        :id => Ishibashi::Application.config.authentication.service_id,
        :token => token
    end
    assert_redirected_to :controller => :users,
      :action => :show,
      :domain_name => @user1.domain_name,
      :screen_name => @user1.screen_name
    assert_not_nil assigns(:user)
    assert_equal @user1.id, session[:user_id]

    WebMock.reset!
  end

  test "login_completeに不正な署名が来たら蹴る" do
    get :login_complete, :id => Ishibashi::Application.config.authentication.service_id
    assert_response :forbidden
  end

  test "login_completeは引き渡された認証情報が不正なら蹴る" do
    WebMock.stub_request(:get, /#{Ishibashi::Application.config.authentication.entry_point}\/retrieve\?.*/).to_return(
      :body => 'invalid data'
    )

    payload = {'key' => 'auth key', 'exp' => 5.minutes.from_now.to_i}
    token = JWT.encode(payload, Ishibashi::Application.config.authentication.key)
    assert_no_difference  'User.count' do
      get :login_complete,
        :id => Ishibashi::Application.config.authentication.service_id,
        :token => token
    end
    assert_response :forbidden

    WebMock.reset!
  end

  test "logoutはセッションのログイン情報を消し、認証サービスからもログアウトさせる" do
    get :logout, {}, {:user_id => @user1.id}
    assert_response :redirect
    assert @response.header['Location'] =~ /logout/
  end

  test "updateは署名が正当ならその内容でuserを更新する(Kitugachi認証サービスからのPOST)" do
    payload = {
      'id' => Ishibashi::Application.config.authentication.service_id,
      'profile_id' => @user1.kitaguchi_profile_id,
      'nickname' => 'new nickname',
      'profile_text' => 'new profile text',
      'exp' => 5.minutes.from_now.to_i
    }

    post :update, :token => JWT.encode(payload, Ishibashi::Application.config.authentication.key)

    assert_response :success
    assert_not_nil assigns(:user)
    assert_equal 'new nickname', assigns(:user).nickname
  end

  test "updateは署名が不正なら蹴る(Kitugachi認証サービスからのPOST)" do
    payload = {
      'id' => Ishibashi::Application.config.authentication.service_id,
      'profile_id' => @user1.kitaguchi_profile_id,
      'nickname' => 'new nickname',
      'profile_text' => 'new profile text',
      'exp' => 5.minutes.from_now.to_i
    }

    post :update, :token => JWT.encode(payload, 'wrong key')

    assert_response :forbidden
  end

  test "セッションが有効なら署名チェックせずに更新する(設定画面からのPOST)" do
    params = {:user => {:private => 1}, :format => :json}
    patch :update, params, {:user_id => @user1.id}
    assert_response :success
    assert assigns(:login_user).private
  end

  test "公開ユーザの場合、ゲストが表示できる" do
    get :show,
      {:domain_name => @user1.domain_name, :screen_name => @user1.screen_name}
    assert_response :success
  end

  test "公開ユーザの場合、他のユーザが表示できる" do
    get :show,
      {:domain_name => @user1.domain_name, :screen_name => @user1.screen_name},
      {:user_id => @user2.id}
    assert_response :success
  end

  test "公開ユーザの場合、本人が表示できる" do
    get :show,
      {:domain_name => @user1.domain_name, :screen_name => @user1.screen_name},
      {:user_id => @user1.id}
    assert_response :success
  end

  test "非公開ユーザの場合、ゲストは表示できない" do
    get :show,
      {:domain_name => @user2.domain_name, :screen_name => @user2.screen_name}
    assert_response :forbidden
  end

  test "非公開ユーザの場合、他のユーザは表示できない" do
    get :show,
      {:domain_name => @user2.domain_name, :screen_name => @user2.screen_name},
      {:user_id => @user1.id}
    assert_response :forbidden
  end

  test "非公開ユーザの場合、本人は表示できる" do
    get :show,
      {:domain_name => @user2.domain_name, :screen_name => @user2.screen_name},
      {:user_id => @user2.id}
    assert_response :success
  end

  test "非公開でランダムキー無効のユーザのフィードは出力されない" do
    get :feeds,
      {:id => @user2.id, :format => :rdf}
    assert_response :forbidden
  end

  test "非公開でキー有効のユーザのフィードはキー付きで取り出せる" do
    get :feeds,
      {:id => @user3.random_key, :format => :rdf}
    assert_response :success
  end

  test "非公開でキー有効のユーザのフィードをキーなしでは取り出せない" do
    get :feeds,
      {:id => @user3.id, :format => :rdf}
    assert_response :forbidden
  end

  test "feeds/:id.icsはvalidなiCalendarを返す" do
    get :feeds,
      {:id => @user1.id, :format => :ics}

    assert_response :success
    assert_nothing_raised RuntimeError do
      ics = Icalendar.parse(@response.body)
      assert_not_nil ics.first

      titles = @user1.user_products.where(:type_name => 'search').map{|up| up.product.title}.sort
      assert_equal titles, ics.first.events.map{|event| event.summary}.sort
    end
  end

  test "feeds/:id.rdfはvalidなRSSを返す" do
    get :feeds,
      {:id => @user1.id, :format => :rdf}

    assert_response :success
    assert_nothing_raised RSS::NotWellFormedError do
      rss = RSS::Parser.parse(@response.body)
      assert_not_nil rss
      assert_equal "#{@user1.nickname}: 発売日一覧: #{Ishibashi::Application.config.title}", rss.channel.about
      assert_equal @user1.user_products.where(:type_name => 'search').count, rss.items.size
      titles = @user1.user_products.where(:type_name => 'search').map{|up| up.product.title}.sort
      assert_equal titles, rss.items.map{|item| item.description }.sort
    end
  end
end
