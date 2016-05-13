require 'test_helper'
require_relative '../../bin/bot/cabocha_wrapper'

class CabochaTest < ActiveSupport::TestCase
  setup do
    parser = CaboChaWrapper::Parser.new
    @tree = parser.parse('今日は朝から夜だった。')
  end

  test 'チャンクが生成される' do
    chunks = @tree.chunks

    assert_equal ['今日', 'は'], chunks[0].tokens.map(&:surface)
    assert_equal ['朝', 'から'], chunks[1].tokens.map(&:surface)
    assert_equal ['夜', 'だっ', 'た', '。'], chunks[2].tokens.map(&:surface)
  end

  test '係り受けが保持される' do
    chunks = @tree.chunks

    assert_equal chunks[2], chunks[0].link
    assert_equal chunks[2], chunks[1].link
    assert chunks[2].link.nil?
  end
end
