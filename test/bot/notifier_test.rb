require 'test_helper'
require_relative '../../lib/bot/notifier'

class DokushoBiyoriBotNotifierTest < ActiveSupport::TestCase
  setup do
    @rest = MiniTest::Mock.new

    rest = MiniTest::Mock.new
    rest.expect(:user, Twitter::User.new(:id => 0, :screen_name => 'bot'))
    rest.expect(:follower_ids, {:ids => []})
    conf = MiniTest::Mock.new
    conf.expect(:"consumer_key=", '', [String])
    conf.expect(:"consumer_secret=", '', [String])
    conf.expect(:"access_token=", '', [String])
    conf.expect(:"access_token_secret=", '', [String])
    Twitter::REST::Client.stub(:new, rest, conf) do
      @notifier = DokushoBiyoriBot::Notifier.new(Ishibashi::Application.config.twitter.update(:product_page_url => 'https://dokusho.yumenosora.net/products'))
    end
    @notifier.instance_variable_set('@rest', @rest)

    Ishibashi::Application.config.bot_user_id = users(:bot_user).id

    @bot_keywords = (1..3).map{|i| bot_keywords("bot_keyword#{i}".to_sym) }
    @twitter_users = @bot_keywords.map{|bk| Twitter::User.new(:id => bk.twitter_user_id, :screen_name => "bot-user-#{bk.twitter_user_id}") }
  end

  test "フォローされていないユーザの要求を削除" do
    @notifier.instance_variable_set('@followers', [2, 3])
    assert_difference 'BotKeyword.count', -1 do
      assert_difference 'UserKeyword.count', -1 do
        @notifier.clean_unfollower
      end
    end
  end

  test "通知をまとめて返却" do
    @rest.expect(:users, @twitter_users, [@bot_keywords.map(&:twitter_user_id)])
    actual = @notifier.notify_targets

    assert_equal @twitter_users, actual.keys
    assert_equal @bot_keywords, actual.values.flat_map(&:keys)
    assert_equal [KeywordProduct], actual.values.map(&:values).flatten.map(&:class).uniq
  end

  test "当日通知のみ" do
    bot_keyword = @bot_keywords.last
    bot_keyword.update_attribute(:notify_at, 0)
    user = @twitter_users.find{|u| u.id == bot_keyword.twitter_user_id }
    keyword_product = keyword_products(:bot_keyword_product_1)
    product = keyword_product.product

    actual = @notifier.create_message(user, {bot_keyword => [keyword_product]})
    expected = [
      "@#{user.screen_name} ",
      "#{product.title}の発売日です。",
      "詳細は→https://dokusho.yumenosora.net/products/#{product.ean}"
    ].join
    assert_equal expected, actual
  end

  test "情報通知単体のみ" do
    bot_keyword = @bot_keywords.last
    user = @twitter_users.find{|u| u.id == bot_keyword.twitter_user_id }
    keyword_product = keyword_products(:bot_keyword_product_1)
    product = keyword_product.product

    actual = @notifier.create_message(user, {bot_keyword => [keyword_product]})
    expected = [
      "@#{user.screen_name} ",
      "#{product.title}の発売日は#{product.release_date.strftime('%m月%d日')}です。",
      "詳細は→https://dokusho.yumenosora.net/products/#{product.ean}"
    ].join
    assert_equal expected, actual
  end

  test "当日通知＋情報通知" do
    user = @twitter_users.find{|u| u.id == @bot_keywords.first.twitter_user_id }
    @bot_keywords[0].update_attribute(:notify_at, 0)
    product = keyword_products(:bot_keyword_product_1).product
    product2 = keyword_products(:bot_keyword_product_2).product
    notifications = {
      @bot_keywords[0] => [keyword_products(:bot_keyword_product_1)],
      @bot_keywords[1] => [keyword_products(:bot_keyword_product_2)]
    }

    actual = @notifier.create_message(user, notifications)
    expected = [
      "@#{user.screen_name} ",
      "#{product.title}の発売日です。",
      "他には#{product2.title}、",
      "詳細は→https://dokusho.yumenosora.net/products/#{product.ean}?ean[]=#{product2.ean}"
    ].join
    assert_equal expected, actual
  end

  test "当日通知複数" do
    bot_keyword = @bot_keywords.last
    bot_keyword.update_attribute(:notify_at, 0)
    user = @twitter_users.find{|u| u.id == bot_keyword.twitter_user_id }
    keyword_products = [
      keyword_products(:bot_keyword_product_1),
      keyword_products(:bot_keyword_product_2),
    ]
    product = keyword_products[0].product
    product2 = keyword_products[1].product

    actual = @notifier.create_message(user, {bot_keyword => keyword_products})
    expected = [
      "@#{user.screen_name} ",
      "#{product.title}の発売日です。",
      "他には#{product2.title}、",
      "詳細は→https://dokusho.yumenosora.net/products/#{product.ean}?ean[]=#{product2.ean}"
    ].join
    assert_equal expected, actual
  end

  test "当日通知複数で多い場合" do
    bot_keyword = @bot_keywords.last
    bot_keyword.update_attribute(:notify_at, 0)
    user = @twitter_users.find{|u| u.id == bot_keyword.twitter_user_id }
    keyword_products = [
      keyword_products(:bot_keyword_product_1),
      keyword_products(:bot_keyword_product_2),
      keyword_products(:bot_keyword_product_3)
    ]
    product = keyword_products[0].product
    product2 = keyword_products[1].product
    product3 = keyword_products[2].product

    actual = @notifier.create_message(user, {bot_keyword => keyword_products})
    expected = [
      "@#{user.screen_name} ",
      "#{product.title}の発売日です。",
      "他に#{product2.title}等、",
      "詳細は→https://dokusho.yumenosora.net/products/#{product.ean}?ean[]=#{product2.ean}&ean[]=#{product3.ean}"
    ].join
    assert_equal expected, actual
  end
end
