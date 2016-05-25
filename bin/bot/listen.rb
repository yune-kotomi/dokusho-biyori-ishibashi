require_relative '../../lib/bot/listener'

config = Ishibashi::Application.config.twitter
logger = Logger.new("#{Rails.root}/log/listen.log")
ActiveRecord::Base.logger = logger
listener = DokushoBiyoriBot::Listener.new(config, logger)

logger.info '受信開始'
listener.connect
