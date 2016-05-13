require 'test_helper'

class BotKeywordTest < ActiveSupport::TestCase
  [
    'ゆゆ式の発売日を教えて。',
    'ゆゆ式の発売日が知りたい',
    'ゆゆ式の新刊を通知',
    'ゆゆ式の最新刊が出る日を知らせて。',
    'ゆゆ式の発売日'
  ].each do |message|
    test "#{message}: 単一キーワードによる情報通知" do
      k = BotKeyword.new(:notify_at => 365)
      k.parse(message)

      assert_equal 'ゆゆ式', k.keyword
      assert k.notify_at.nil?
      assert !k.uncertain
    end
  end

  [
    'ゆゆ式の発売日で教えて。',
    'ゆゆ式の発売日に知りたい',
    'ゆゆ式の最新刊が出る日に知らせて。',
    'ゆゆ式の発売日になったら通知して欲しいんだけど。',
  ].each do |message|
    test "#{message}: 当日通知" do
      k = BotKeyword.new(:notify_at => 365)
      k.parse(message)

      assert_equal 'ゆゆ式', k.keyword
      assert_equal 0, k.notify_at
      assert !k.uncertain
    end
  end

  (1..9).each do |i|
    message = "ゆゆ式の発売日の#{i}日前に教えて。"
    test message do
      k = BotKeyword.new(:notify_at => 365)
      k.parse(message)

      assert_equal 'ゆゆ式', k.keyword
      assert_equal i, k.notify_at
      assert !k.uncertain
    end

    m = "ゆゆ式の発売日の#{i}日後に通知。"
    test m do
      k = BotKeyword.new(:notify_at => 365)
      k.parse(m)

      assert_equal 'ゆゆ式', k.keyword
      assert_equal i * -1, k.notify_at
      assert !k.uncertain
    end
  end
end
