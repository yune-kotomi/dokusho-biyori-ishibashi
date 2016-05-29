require 'test_helper'
require 'yahoo_da'

class YahooDATest < ActiveSupport::TestCase
  setup do
    parser = YahooDA::Parser.new(:app_id => 'APPID')
    sentence = 'うちの庭には二羽鶏がいます。'
    mock_yahoo_da('APPID', sentence)
    @tree = parser.parse(sentence)
  end

  test 'チャンクが生成される' do
    chunks = @tree.chunks

    assert_equal ['うち', 'の'], chunks[0].surfaces
    assert_equal ['庭', 'に', 'は'], chunks[1].surfaces
    assert_equal ['二羽', '鶏', 'が'], chunks[2].surfaces
    assert_equal ['い', 'ます', '。'], chunks[3].surfaces
  end

  test '係り受けが保持される' do
    chunks = @tree.chunks

    assert_equal chunks[1], chunks[0].link
    assert_equal chunks[3], chunks[1].link
    assert_equal chunks[3], chunks[2].link
    assert chunks[3].link.nil?
  end

  test 'Chunk#contains?' do
    list = ['庭', '鶏']
    assert !@tree.chunks[0].contains?(list)
    assert @tree.chunks[1].contains?(list)
  end

  test '文中でのトークンの位置' do
    token = @tree.chunks[2].tokens.first
    assert_equal (6..7), token.position
  end
end

# data = YAML.load(open('test/fixtures/yahoo_da.txt'))
# appid = Ishibashi::Application.config.yahoo_app_id
# sentences.each do |sentence|
#   data[sentence]=open("http://jlp.yahooapis.jp/DAService/V1/parse?appid=#{appid}&sentence=#{CGI.escape(sentence)}").read
#   sleep 1
# end
# open('test/fixtures/yahoo_da.txt','w'){|f|f.puts data.to_yaml}
