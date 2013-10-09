module Shadowcell
  class Flusher < RedisifiedActor

    def flush user_id
      count = 0
      while msg = @redis.rpop("user-locations-#{user_id}") do
        count += 1
        @redis.lpush PUB_CHANNEL, msg
      end
      LOGGER.debug "flushed #{count} msgs back into #{PUB_CHANNEL}"
    end

  end
end
