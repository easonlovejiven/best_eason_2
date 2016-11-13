$redis = Redis.new(:host => REDIS_CONFIG['host'], :port => REDIS_CONFIG['port'], db: REDIS_CONFIG['db'])
Redis.current = Redis.new(:host => REDIS_CONFIG['host'], :port => REDIS_CONFIG['port'], db: REDIS_CONFIG['db'])
