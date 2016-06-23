require 'test_helper'
require_relative '../../lib/bot/listener'

class DokushoBiyoriBotListenerTest < ActiveSupport::TestCase
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
      @listener = DokushoBiyoriBot::Listener.new(Ishibashi::Application.config.twitter.update(:product_page_url => 'https://dokusho.yumenosora.net/products'), Logger.new("/dev/null"))
    end
    @listener.instance_variable_set('@rest', @rest)

    bot_user = User.new
    bot_user.save
    Ishibashi::Application.config.bot_user_id = bot_user.id
  end

  test '自分宛ではないtweetは無視する' do
    message = Twitter::Tweet.new(:id => 1, :text => 'にゃー')
    @rest.expect(:update, Twitter::Tweet.new(:id => 0), [String, Hash])
    @listener.tweet_received(message)
    assert_raises(::MockExpectationError) { @rest.verify }
  end

  test '自分宛だがフォローされてない相手からのmentionは無視する' do
    message = Twitter::Tweet.new(:id => 1, :text => '@bot にゃー')
    @rest.expect(:update, Twitter::Tweet.new(:id => 0), [String, Hash])
    @listener.tweet_received(message)
    assert_raises(::MockExpectationError) { @rest.verify }
  end

  test 'フォロワーからの自分宛mentionを解釈し、応答する' do
    str = '三上小又のゆゆ式の発売日を教えて。'
    reply = '@user はい、「三上 小又 ゆゆ式」で検索して次作の発売日が分かり次第お知らせします。'

    message = Twitter::Tweet.new(
      :id => 1,
      :text => "@bot #{str}",
      :user => {:id => 1, :screen_name => 'user'}
    )
    @rest.expect(:update, Twitter::Tweet.new(:id => 0), [reply, Hash])
    mock_yahoo_da('APPID', str)
    @listener.instance_variable_set('@followers', [1])

    AmazonEcs.stub(:search, [0, []]) do
      assert_difference 'BotKeyword.count' do
        @listener.tweet_received(message)
      end
    end
    @rest.verify
  end

  test '発売を控えた商品がある場合はその旨通知に足す' do
    str = 'ゆゆ式の発売日を教えて。'
    keyword_product = keyword_products(:bot_keyword_product_yuyushiki)
    product = products(:bot_product2)
    reply = "@user #{product.title}が#{product.release_date.month}月#{product.release_date.day}日発売です。詳細はhttps://dokusho.yumenosora.net/products/#{product.ean} また「ゆゆ式」で検索して次作の発売日が分かり次第お知らせします。"

    message = Twitter::Tweet.new(
      :id => 1,
      :text => "@bot #{str}",
      :user => {:id => 1, :screen_name => 'user'}
    )
    @rest.expect(:update, Twitter::Tweet.new(:id => 0), [reply, Hash])
    mock_yahoo_da('APPID', str)
    @listener.instance_variable_set('@followers', [1])

    AmazonEcs.stub(:search, [0, []]) do
      assert_difference 'BotKeyword.count' do
        @listener.tweet_received(message)
      end
    end
    @rest.verify
    assert_equal [keyword_product.id], BotKeyword.order(:created_at).last.sent_keyword_product_id
  end

  test '自分のtweetのリツイートは無視する(replyに見えるので誤認しないように)' do
    str = '三上小又のゆゆ式の発売日を教えて。'
    message = Twitter::Tweet.new(
      :id => 1,
      :text => "@bot #{str}",
      :user => {:id => 1, :screen_name => 'user'},
      :retweeted_status => Twitter::Tweet.new(:id => 2)
    )
    @listener.instance_variable_set('@followers', [1])
    @rest.expect(:update, Twitter::Tweet.new(:id => 0), [String, Hash])
    @listener.tweet_received(message)
    assert_raises(::MockExpectationError) { @rest.verify }
  end

  test 'キーワードを含まないmentionには反応しない' do
    str = '三上小又のゆゆ式'

    message = Twitter::Tweet.new(
      :id => 1,
      :text => "@bot #{str}",
      :user => {:id => 1, :screen_name => 'user'}
    )
    @rest.expect(:update, Twitter::Tweet.new(:id => 0), [String, Hash])
    @listener.instance_variable_set('@followers', [1])
    @listener.tweet_received(message)
    assert_raises(::MockExpectationError) { @rest.verify }
  end

  test 'フォロー通知でフォロワーリストを更新' do
    event = Twitter::Streaming::Event.new(
      :event => 'follow',
      :source => {:id => 1},
      :target => {:id => 0}
    )
    @listener.event_received(event)
    list = @listener.instance_variable_get('@followers')
    assert list.include?(1)
  end

  test '鍵ユーザにはフォローを返す' do
    event = Twitter::Streaming::Event.new(
      :event => 'follow',
      :source => {:id => 2, :protected => true},
      :target => {:id => 0}
    )
    @rest.expect(:follow, [Twitter::User.new(:id => 2)], [Twitter::User])
    @listener.event_received(event)
  end
end
