config = Ishibashi::Application.config.twitter
logger = Logger.new("#{Rails.root}/log/listen.log")
listener = DokushoBiyoriBot::Listener.new(config, logger)
listener.connect
