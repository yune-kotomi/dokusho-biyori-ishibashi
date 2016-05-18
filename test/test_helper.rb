ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'rr'

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  def mock_yahoo_da(app_id, sentence)
    WebMock.reset!
    open('test/fixtures/yahoo_da.txt') do |f|
      data = YAML.load(f.read)
      url = "http://jlp.yahooapis.jp/DAService/V1/parse?appid=#{app_id}&sentence=#{CGI.escape(sentence)}"
      WebMock.stub_request(:get, url).to_return(:body => data[sentence])
      raise 'YahooDA解析結果がフィクスチャに無い' if data[sentence].nil?
    end
  end
end
