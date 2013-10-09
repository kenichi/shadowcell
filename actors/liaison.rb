module Shadowcell
  class Liaison < RedisifiedActor

    attr_accessor :registrar, :profiler, :updater

    def liaise data, &block
      aci = CONFIG['ago']['apps'][data['client_id']]['client_id']
      reg_future = @registrar.future.register aci
      pro_future = @profiler.future.profile data['user_id']

      user_data = {
        ago: reg_future.value,
        geoloqi: pro_future.value
      }

      @redis.set "user-#{data['user_id']}", user_data.to_json

      tags = []
      user_data[:geoloqi]['subscriptions'].each do |layer|
        tags << "layer_id:#{layer}"
      end

      at = user_data[:ago]['deviceToken']['access_token']
      @updater.async.update at, tags, &block
    end

  end
end
