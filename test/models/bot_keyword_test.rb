require 'test_helper'

class BotKeywordTest < ActiveSupport::TestCase
  setup do
    @amazon = YAML.load(open('test/fixtures/amazon.txt').read)

    bot_user = users(:bot_user)
    Ishibashi::Application.config.bot_user_id = bot_user.id

    @bot_keyword = bot_keywords(:bot_keyword1)
    date = Time.now.beginning_of_day
    @bot_keyword.user_keyword.keyword.keyword_products.map(&:product).each{|product| product.update_attributes(:a_release_date => date, :r_release_date => date) }
  end

  [
    'コトノバドライブの発売日を教えて。',
    'コトノバドライブの発売日が知りたい',
    'コトノバドライブの新刊を通知',
    'コトノバドライブの最新刊が出る日を知らせて。'
  ].each do |message|
    test "#{message}: 単一キーワードによる情報通知" do
      mock_yahoo_da('APPID', message)

      k = BotKeyword.new(:notify_at => 365)
      AmazonEcs.stub(:search, [0, []]) do
        k.parse(message)
      end

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
      AmazonEcs.stub(:search, [0, []]) do
        k.parse(message)
      end

      assert_equal 'コトノバドライブ', k.keyword
      assert_equal 0, k.notify_at
      assert !k.uncertain
    end
  end

  (1..7).each do |i|
    message = "コトノバドライブの発売日の#{i}日前に教えて。"
    test message do
      mock_yahoo_da('APPID', message)

      k = BotKeyword.new(:notify_at => 365)
      AmazonEcs.stub(:search, [0, []]) do
        k.parse(message)
      end

      assert_equal 'コトノバドライブ', k.keyword
      assert_equal i, k.notify_at
      assert !k.uncertain
    end

    m = "コトノバドライブの発売日の#{i}日後に通知。"
    test m do
      mock_yahoo_da('APPID', m)

      k = BotKeyword.new(:notify_at => 365)
      AmazonEcs.stub(:search, [0, []]) do
        k.parse(m)
      end

      assert_equal 'コトノバドライブ', k.keyword
      assert_equal i * -1, k.notify_at
      assert !k.uncertain
    end
  end

  test '発売日周辺の通知は前後7日間に限定' do
    message = "コトノバドライブの発売日の8日前に教えて。"
    mock_yahoo_da('APPID', message)

    k = BotKeyword.new(:notify_at => 365)
    AmazonEcs.stub(:search, [0, []]) do
      k.parse(message)
    end

    assert_equal 'コトノバドライブ', k.keyword
    assert_equal 7, k.notify_at
    assert !k.uncertain

    message = "コトノバドライブの発売日の8日後に通知。"
    mock_yahoo_da('APPID', message)

    k = BotKeyword.new(:notify_at => 365)
    AmazonEcs.stub(:search, [0, []]) do
      k.parse(message)
    end

    assert_equal 'コトノバドライブ', k.keyword
    assert_equal -7, k.notify_at
    assert !k.uncertain
  end

  test '複数キーワードによる要求' do
    message = '成瀬ちさとの東雲侑子は短編小説をあいしているの発売日を教えて。'
    mock_yahoo_da('APPID', message)

    k = BotKeyword.new(:notify_at => 365)
    assert_difference 'Keyword.count' do
      assert_difference 'UserKeyword.count' do
        AmazonEcs.stub(:search, [0, []]) do
          k.parse(message)
        end
      end
    end

    expected = '成瀬 ちさと 東雲侑子は短編小説をあいしている'
    assert_equal expected, k.keyword
    assert k.notify_at.nil?
    assert !k.uncertain
    assert_equal expected, UserKeyword.find(k.user_keyword_id).keyword.value
  end

  test '未知と既知のキーワードの組み合わせ' do
    message = '三上小又のゆゆ式の発売日を教えて。'
    mock_yahoo_da('APPID', message)

    k = BotKeyword.new(:notify_at => 365)
    AmazonEcs.stub(:search, [0, []]) do
      k.parse(message)
    end

    assert_equal '三上 小又 ゆゆ式', k.keyword
    assert k.notify_at.nil?
    assert !k.uncertain
  end

  test 'キーワードのみによる要求' do
    message = 'ゆゆ式'
    mock_yahoo_da('APPID', message)

    k = BotKeyword.new(:notify_at => 365)
    assert_no_difference 'Keyword.count' do
      assert_difference 'UserKeyword.count' do
        AmazonEcs.stub(:search, [0, []]) do
          k.parse(message)
        end
      end
    end

    assert_equal 'ゆゆ式', k.keyword
    assert k.notify_at.nil?
    assert k.uncertain
  end

  test '情報通知すべき対象を返す' do
    Time.stub(:now, 10.days.ago) do
      actual = @bot_keyword.keyword_products_to_notify
      expected = [products(:product1).id, products(:product2).id].sort
      assert_equal expected, actual.map(&:product).map(&:id).sort
    end
  end

  test '送信済みは除外して返す' do
    sent = @bot_keyword.user_keyword.keyword.keyword_products.where(:product_id => products(:product1).id).first
    @bot_keyword.sent_keyword_product_id.push(sent.id)

    Time.stub(:now, 10.days.ago) do
      actual = @bot_keyword.keyword_products_to_notify
      expected = [products(:product2).id].sort
      assert_equal expected, actual.map(&:product).map(&:id).sort
    end
  end

  test '当日通知すべき対象を返す' do
    expected = [products(:product1).id, products(:product2).id].sort

    (7..-7).each do |i|
      @bot_keyword.notify_at = i
      Time.stub(:now, i.days.ago) do
        actual = @bot_keyword.keyword_products_to_notify
        assert_equal expected, actual.map(&:product).map(&:id).sort
      end
    end
  end
end
