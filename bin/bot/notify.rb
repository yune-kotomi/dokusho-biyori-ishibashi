config = Ishibashi::Application.config.twitter
logger = Logger.new("#{Rails.root}/log/notify.log")
rest = Twitter::REST::Client.new do |c|
  c.consumer_key = config[:consumer][:key]
  c.consumer_secret = config[:consumer][:secret]
  c.access_token = config[:access][:key]
  c.access_token_secret = config[:access][:secret]
end

# フォロワー一覧
followers = rest.follower_ids.to_h[:ids]

# フォロー解除されたユーザのbot_keywordを削除
BotKeyword.all.
  reject{|bk| followers.include?(bk.twitter_user_id) }.
  each do |bk|
    bk.destroy
  end
