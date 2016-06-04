module DokushoBiyoriBot
  class Listener
    def initialize(config, logger = Logger.new(STDOUT))
      @stream = Twitter::Streaming::Client.new do |c|
        c.consumer_key = config[:consumer][:key]
        c.consumer_secret = config[:consumer][:secret]
        c.access_token = config[:access][:key]
        c.access_token_secret = config[:access][:secret]
      end
      @rest = Twitter::REST::Client.new do |c|
        c.consumer_key = config[:consumer][:key]
        c.consumer_secret = config[:consumer][:secret]
        c.access_token = config[:access][:key]
        c.access_token_secret = config[:access][:secret]
      end

      @logger = logger

      # 自分が誰なのか
      @current_user = @rest.user
      @followers = @rest.follower_ids.to_h[:ids]

      # 商品ページ
      @product_page_url = config[:product_page_url]
    end

    # streaming接続実行、待ち受け開始
    def connect
      @stream.user {|m| received(m) }
    end

    def received(message)
      case message
      when Twitter::Tweet
        tweet_received(message)

      when Twitter::Streaming::Event
        event_received(message)

      when Twitter::Streaming::FriendList
        # いらない
      else
        @logger.info "unknown message: #{message.inspect}"
      end
    end

    def tweet_received(tweet)
      # フォロワーからの自分宛のmentionのみ解釈する
      mention_marker = "@#{@current_user.screen_name}"
      if tweet.text.include?(mention_marker) && @followers.include?(tweet.user.id) && !tweet.retweet?
        # 要求文解釈
        @bot_keyword = BotKeyword.new(
          :tweet_id => tweet.id,
          :twitter_user_id => tweet.user.id,
          :twitter_user_screen_name => tweet.user.screen_name
        )
        if @bot_keyword.keyword_included?(tweet.text)
          @bot_keyword.parse(tweet.text.sub(mention_marker, '').strip)
          @bot_keyword.save

          unless @bot_keyword.uncertain
            @tweet = tweet
            notify_targets = @bot_keyword.keyword_products_to_notify(nil)
            if notify_targets.present?
              keyword_product = notify_targets.first
              @product = keyword_product.product
              @product_page = "#{@product_page_url}/#{@product.ean}"

              templates = ['reply_with_product', 'reply', 'reply_short'].
                map{|f| File.join(Rails.root, "lib/bot/views/listener/#{f}.text.erb") }
              reply = render(templates)
            else
              templates = ['reply', 'reply_short'].
                map{|f| File.join(Rails.root, "lib/bot/views/listener/#{f}.text.erb") }
              reply = render(templates)
            end
          end

          # 応答実行
          @rest.update(reply, :in_reply_to_status => tweet)

          if @bot_keyword.notify_at.nil? && @product_page.present? && reply.include?(@product_page)
            @bot_keyword.notified(keyword_product)
            @bot_keyword.save
          end
        else
          @logger.info "キーワードが含まれていない: #{tweet.text}"
        end
      end
    rescue => e
      @logger.error "#{e.inspect} #{e.backtrace}"
    end

    def event_received(event)
      # フォロー通知ならフォロワーに追加
      if event.name == :follow && event.target.id == @current_user.id
        @followers.push(event.source.id)
      else
        @logger.info "unknown event: #{event.name} #{event.inspect}"
      end
    end

    private
    def render(templates)
      templates.map{|path| ERB.new(open(path).read) }.
        map{|t| t.result(binding)}.
        map{|r| r.gsub(/^ +/, '').gsub("\n", '') }.
        sort{|a, b| b.size <=> a.size }.
        reject{|r| r.gsub(@product_page || 'a' * 24, 'a' * 24).size > 140 }.
        first
    end
  end
end
