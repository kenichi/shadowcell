module Shadowcell
  class Liaison < UberActor

    attr_accessor :flusher, :profiler, :registrar, :updater

    def liaise data
      aci = CONFIG['ago']['apps'][data['client_id'].to_i]['client_id']
      reg_future = @registrar.future.register aci, data['user_id']
      pro_future = @profiler.future.profile data['user_id']

      user_data = {
        'ago' => reg_future.value,
        'geoloqi' => pro_future.value
      }

      key = "user-#{data['user_id']}"
      LOGGER.debug "setting '#{key}'"
      @redis.set key, user_data.to_json

      tags = []
      user_data['geoloqi']['subscriptions'].each do |layer|
        tags << "layer_id:#{layer}"
      end

      at = user_data['ago']['deviceToken']['access_token']
      @updater.async.update at, tags, data['user_id']
      @flusher.async.flush data['user_id']
    end

  end
end
