module Shadowcell
  class Reporter < RedisifiedActor
    extend Stoppable

    def report

      keys = @redis.keys '*'
      queues = keys.select {|k| k =~ /user-locations-.*/}
      user_datas = keys - queues - [PUB_CHANNEL]
      queue_lengths = queues.map {|q| @redis.llen q}
      max_queued = queue_lengths.reduce(0) {|max, l| max = l if l > max; max}
      min_queued = queue_lengths.reduce(max_queued) {|min, l| min = l if l < min; min}
      total_queued = queue_lengths.reduce :+
      locations_updated = @redis.get POST_COUNT_KEY

      LOGGER.info "#{user_datas.length} devices registered"
      LOGGER.info "#{locations_updated} locations updated"
      LOGGER.info "#{total_queued} location updates in #{queues.length} queues"
      LOGGER.info "max: #{max_queued} min: #{min_queued}"

      after(5){ Celluloid::Actor.current.async.report } unless Reporter.stop?

    end

  end
end
