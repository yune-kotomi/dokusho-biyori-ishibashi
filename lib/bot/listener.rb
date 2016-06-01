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
        bot_keyword = BotKeyword.new(
          :tweet_id => tweet.id,
          :twitter_user_id => tweet.user.id,
          :twitter_user_screen_name => tweet.user.screen_name
        )
        if bot_keyword.keyword_included?(tweet.text)
          bot_keyword.parse(tweet.text.sub(mention_marker, '').strip)
          bot_keyword.save
          # 応答組み立て
          header = "@#{tweet.user.screen_name} "
          answer = "はい。"
          recent = ''
          product_page = ''
          keyword = ''

          unless bot_keyword.uncertain
            notify_targets = bot_keyword.keyword_products_to_notify(nil)
            if notify_targets.present?
              keyword_product = notify_targets.first
              product = keyword_product.product
              recent = "#{product.title}が#{product.release_date.month}月#{product.release_date.day}日発売です。詳細は→"
              product_page = "#{@product_page_url}/#{product.ean} "

              keyword = "また「#{bot_keyword.keyword}」で検索して"
              if bot_keyword.notify_at.nil?
                keyword += "次作の発売日が分かり次第お知らせします。"
              else
                if bot_keyword.notify_at == 0
                  keyword += "発売日にお知らせします。"
                elsif bot_keyword.notify_at < 0
                  keyword += "発売日の#{bot_keyword.notify_at * -1}日後にお知らせします。"
                else
                  keyword += "発売日の#{bot_keyword.notify_at}日前にお知らせします。"
                end
              end
            else
              keyword = "はい、「#{bot_keyword.keyword}」で検索して"

              if bot_keyword.notify_at.nil?
                keyword += "発売日が分かり次第お知らせします。"
              else
                if bot_keyword.notify_at == 0
                  keyword += "発売日にお知らせします。"
                elsif bot_keyword.notify_at < 0
                  keyword += "発売日の#{bot_keyword.notify_at * -1}日後にお知らせします。"
                else
                  keyword += "発売日の#{bot_keyword.notify_at}日前にお知らせします。"
                end
              end
            end
          end

          # 応答文組み立て
          text = [header, recent, keyword].join
          if product_page.present? && text.size <= 140-25 # URL+スペース
              reply = [header, recent, product_page, keyword].join

              if bot_keyword.notify_at.nil?
                bot_keyword.notified(keyword_product)
                bot_keyword.save
              end
          elsif keyword.present? && text.size <= 140
            reply = [header, keyword].join
          else
            reply = [header, answer].join
          end
          # 応答実行
          @rest.update(reply, :in_reply_to_status => tweet)
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
  end
end
