# coding: utf-8
require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  def sign(message)
    OpenSSL::HMAC::hexdigest(
      OpenSSL::Digest::SHA256.new,
      Ishibashi::Application.config.authentication.key,
      message
    )
  end

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

    signature = sign([params['id'].first, params['timestamp'].first, 'authenticate'].join)
    assert_equal params['signature'].first, signature
  end

  test "login_completeは認証情報を取得し、問題なければユーザを生成する" do
    t = Time.now
    params = {
      :id => Ishibashi::Application.config.authentication.service_id,
      :key => 'key',
      :timestamp => t.to_i
    }
    params[:signature] = sign([params[:id], params[:key], params[:timestamp], 'deliver'].join)

    new_user = {
      :profile_id => 0,
      :domain_name => 'www.example.com',
      :screen_name => 'screen_name',
      :nickname => 'nickname',
      :profile_text => 'profile',
      :openid_url => 'http://www.example.com/screen_name',
      :timestamp => Time.now.to_i
    }
    new_user[:signature] = sign(
      [
        Ishibashi::Application.config.authentication.service_id, new_user[:profile_id],
        new_user[:domain_name], new_user[:screen_name], new_user[:nickname],
        new_user[:profile_text], new_user[:openid_url], new_user[:timestamp],
        'retrieved'
      ].join
    )

    WebMock.stub_request(:get, /http:\/\/kitaguchi.yumenosora.net\/profile\/retrieve\?.*/).to_return(
      :body => new_user.to_json
    )
  end

  test "login_completeは既存ユーザをログインさせる" do
    t = Time.now
    params = {
      :id => Ishibashi::Application.config.authentication.service_id,
      :key => 'key',
      :timestamp => t.to_i
    }
    params[:signature] = sign([params[:id], params[:key], params[:timestamp], 'deliver'].join)

    user_data = {
      :profile_id => @user1.kitaguchi_profile_id,
      :domain_name => @user1.domain_name,
      :screen_name => @user1.screen_name,
      :nickname => @user1.nickname,
      :profile_text => @user1.profile_text,
      :openid_url => 'http://example.com/screen_name'
    }
    user_data[:signature] = sign(
      [
        Ishibashi::Application.config.authentication.service_id, user_data[:profile_id],
        user_data[:domain_name], user_data[:screen_name], user_data[:nickname],
        user_data[:profile_text], user_data[:openid_url], user_data[:timestamp],
        'retrieved'
      ].join
    )
    WebMock.stub_request(:get, /#{Ishibashi::Application.config.authentication.entry_point}\/retrieve\?.*/).to_return(
      :body => user_data.to_json
    )

    assert_no_difference  'User.count' do
      get :login_complete, params
    end
    assert_redirected_to :controller => :etc, :action => :index
    assert_not_nil assigns(:user)
    assert_equal @user1.id, session[:user_id]

    WebMock.reset!
  end

  test "login_completeに不正な署名が来たら蹴る" do
    t = Time.now
    params = {
      :id => Ishibashi::Application.config.authentication.service_id,
      :key => 'key',
      :timestamp => t.to_i,
      :signature => 'invalid'
    }

    get :login_complete, params
    assert_response :forbidden
  end

  test "login_completeは引き渡された認証情報が不正なら蹴る" do
    t = Time.now
    params = {
      :id => Ishibashi::Application.config.authentication.service_id,
      :key => 'key',
      :timestamp => t.to_i
    }
    params[:signature] = sign([params[:id], params[:key], params[:timestamp], 'deliver'].join)

    new_user = {
      :profile_id => 0,
      :domain_name => 'www.example.com',
      :screen_name => 'screen_name',
      :nickname => 'nickname',
      :profile_text => 'profile',
      :openid_url => 'http://www.example.com/screen_name',
      :timestamp => Time.now.to_i
    }
    new_user[:signature] = 'invalid signature'

    WebMock.stub_request(:get, /#{Ishibashi::Application.config.authentication.entry_point}\/retrieve\?.*/).to_return(
      :body => new_user.to_json
    )

    assert_no_difference  'User.count' do
      get :login_complete, params
    end
    assert_response :forbidden

    WebMock.reset!
  end

  test "logoutはセッションのログイン情報を消し、認証サービスからもログアウトさせる" do
    get :logout, {}, {:user_id => @user1.id}
    assert_response :redirect
    assert @response.header['Location'] =~ /logout/
  end

  test "updateは署名が正当ならその内容でuserを更新する" do
    params = {
      'id' => Ishibashi::Application.config.authentication.service_id,
      'profile_id' => @user1.kitaguchi_profile_id,
      'nickname' => 'new nickname',
      'profile_text' => 'new profile text',
      'timestamp' => Time.now.to_i
    }
    message = [params['id'], params['profile_id'], params['nickname'], params['profile_text'], params['timestamp'], 'update'].join
    params['signature'] = sign(message)

    post :update, params

    assert_response :success
    assert_not_nil assigns(:user)
    assert_equal 'new nickname', assigns(:user).nickname
  end

  test "updateは署名が不正なら蹴る" do
    params = {
      'id' => Ishibashi::Application.config.authentication.service_id,
      'profile_id' => @user1.kitaguchi_profile_id,
      'nickname' => 'new nickname',
      'profile_text' => 'new profile text',
      'timestamp' => Time.now.to_i,
      'signature' => 'invalid'
    }

    post :update, params

    assert_response :forbidden
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
end
