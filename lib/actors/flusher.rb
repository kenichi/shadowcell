module Shadowcell
  class Flusher < RedisifiedActor

    def flush user_id
      key = "user-locations-#{user_id}"
      count = @redis.llen key
      @redis.lpush key, @redis.lrange(key, 0, -1)
      @redis.del key
      LOGGER.debug "flushed #{count} msgs (#{user_id})"
    end

  end
end
