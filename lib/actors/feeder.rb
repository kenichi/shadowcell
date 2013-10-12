module Shadowcell
  class Feeder
    include Celluloid
    extend Stoppable

    def initialize opts = {}
      @sub = Shadowcell.redis_for host: CONFIG['geoloqi']['redis']['host'],
                                  port: CONFIG['geoloqi']['redis']['port']
      @pub = Shadowcell.redis_for host: CONFIG['redis']['host'],
                                  port: CONFIG['redis']['port']
    end

    def feed
      @sub.subscribe SUB_CHANNEL do |on|
        on.message do |channel, msg|
          if monitored_app? msg
            count = @pub.lpush PUB_CHANNEL, msg
            LOGGER.warn "#{count} msg(s) in channel '#{PUB_CHANNEL}'" if count % 100 == 0
          end
          return if Shadowcell::Feeder.stop?
        end
      end
    end

    def monitored_app? msg
      CONFIG['geoloqi']['apps'].keys.include? JSON.parse(msg)['client_id'].to_i
    end

  end
end
