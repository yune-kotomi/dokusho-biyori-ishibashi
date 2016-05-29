require_relative '../../lib/bot/notifier'

config = Ishibashi::Application.config.twitter.update(:product_page_url => 'https://dokusho.yumenosora.net/products')
logger = Logger.new("#{Rails.root}/log/notify.log")
ActiveRecord::Base.logger = logger
notifier = DokushoBiyoriBot::Notifier.new(config, logger)

logger.info '通知開始'

logger.info 'クリーニング実行'
notifier.clean_unfollower

targets = notifier.notify_targets
targets.each do |user, notifications|
  logger.info user.screen_name
  logger.info "BotKeyword: #{notifications.keys.map(&:id)}"
  logger.info "Product: #{notifications.values.flatten.map(&:product).map(&:ean)}"
  notifier.notify(user, notifications)
end

logger.info '通知終了'
