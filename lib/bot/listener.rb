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
          reply = ["@#{tweet.user.screen_name} "]
          if bot_keyword.uncertain
            # よくわからない場合はエコー無しで返答
            reply.push("はい。")
          else
            reply.push("はい、「#{bot_keyword.keyword}」で検索して")

            if bot_keyword.notify_at.nil?
              reply.push("発売日が分かり次第お知らせします。")
            else
              if bot_keyword.notify_at == 0
                reply.push("発売日にお知らせします。")
              elsif bot_keyword.notify_at < 0
                reply.push("発売日の#{bot_keyword.notify_at * -1}日後にお知らせします。")
              else
                reply.push("発売日の#{bot_keyword.notify_at}日前にお知らせします。")
              end
            end

            # 返信が長すぎる場合削る
            reply[1] = 'はい、' if reply.join.size > 140
          end
          # 応答実行
          @rest.update(reply.join, :in_reply_to_status => tweet)
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
