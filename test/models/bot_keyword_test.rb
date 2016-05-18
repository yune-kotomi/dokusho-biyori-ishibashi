require 'test_helper'

class BotKeywordTest < ActiveSupport::TestCase
  [
    'コトノバドライブの発売日を教えて。',
    'コトノバドライブの発売日が知りたい',
    'コトノバドライブの新刊を通知',
    'コトノバドライブの最新刊が出る日を知らせて。'
  ].each do |message|
    test "#{message}: 単一キーワードによる情報通知" do
      mock_yahoo_da('APPID', message)

      k = BotKeyword.new(:notify_at => 365)
      k.parse(message)

      assert_equal 'コトノバドライブ', k.keyword
      assert k.notify_at.nil?
      assert !k.uncertain
    end
  end

  [
    'コトノバドライブの発売日で教えて。',
    'コトノバドライブの発売日に知りたい',
    'コトノバドライブの最新刊が出る日に知らせて。',
    'コトノバドライブの発売日になったら通知して欲しいんだけど。',
  ].each do |message|
    test "#{message}: 当日通知" do
      mock_yahoo_da('APPID', message)

      k = BotKeyword.new(:notify_at => 365)
      k.parse(message)

      assert_equal 'コトノバドライブ', k.keyword
      assert_equal 0, k.notify_at
      assert !k.uncertain
    end
  end

  (1..9).each do |i|
    message = "コトノバドライブの発売日の#{i}日前に教えて。"
    test message do
      mock_yahoo_da('APPID', message)

      k = BotKeyword.new(:notify_at => 365)
      k.parse(message)

      assert_equal 'コトノバドライブ', k.keyword
      assert_equal i, k.notify_at
      assert !k.uncertain
    end

    m = "コトノバドライブの発売日の#{i}日後に通知。"
    test m do
      mock_yahoo_da('APPID', m)

      k = BotKeyword.new(:notify_at => 365)
      k.parse(m)

      assert_equal 'コトノバドライブ', k.keyword
      assert_equal i * -1, k.notify_at
      assert !k.uncertain
    end
  end

  test '複数キーワードによる要求' do
    message = '成瀬ちさとの東雲侑子は短編小説をあいしているの発売日を教えて。'
    mock_yahoo_da('APPID', message)

    k = BotKeyword.new(:notify_at => 365)
    k.parse(message)

    assert_equal '成瀬 ちさと 東雲侑子は短編小説をあいしている', k.keyword
    assert k.notify_at.nil?
    assert !k.uncertain
  end

  test '未知と既知のキーワードの組み合わせ' do
    message = '三上小又のゆゆ式の発売日を教えて。'
    mock_yahoo_da('APPID', message)

    k = BotKeyword.new(:notify_at => 365)
    k.parse(message)

    assert_equal '三上 小又 ゆゆ式', k.keyword
    assert k.notify_at.nil?
    assert !k.uncertain
  end

  test 'キーワードのみによる要求' do
    message = 'ゆゆ式'
    mock_yahoo_da('APPID', message)

    k = BotKeyword.new(:notify_at => 365)
    k.parse(message)

    assert_equal 'ゆゆ式', k.keyword
    assert k.notify_at.nil?
    assert k.uncertain
  end
end
