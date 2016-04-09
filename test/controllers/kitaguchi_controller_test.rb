require 'test_helper'

class KitaguchiControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success

    token = response.body
    payload = JWT.decode(token, Ishibashi::Application.config.authentication.key).first

    keys = ['logo', 'banner', 'root', 'authenticate', 'profile']
    assert_equal keys.sort, payload.keys.sort
    keys.each do |key|
      if key == 'root'
        assert payload[key].start_with?('http')
      else
        payload[key].each do |k, v|
          assert v.start_with?('http')
        end
      end
    end
  end
end
