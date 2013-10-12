module Shadowcell
  class Flusher < RedisifiedActor

    def flush user_id
      key = "user-locations-#{user_id}"

      # count = 0
      # while msg = @redis.rpop(key) do
      #   count += 1
      #   @redis.lpush PUB_CHANNEL, msg
      # end

      count = @redis.llen key
      @redis.lpush key, @redis.lrange(key, 0, -1)
      @redis.del key
      
      LOGGER.debug "flushed #{count} msgs (#{user_id})"
    end

  end
end
