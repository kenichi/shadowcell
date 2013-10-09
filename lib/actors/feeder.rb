module Shadowcell
  class Feeder
    include Celluloid

    def initialize opts = {}
      @sub = Shadowcell.redis_for host: CONFIG['geoloqi']['redis']['host'],
                                  port: CONFIG['geoloqi']['redis']['port']
      @pub = Shadowcell.redis_for host: CONFIG['redis']['host'],
                                  port: CONFIG['redis']['port']
    end

    def feed
      @sub.subscribe SUB_CHANNEL do |on|
        on.message do |channel, msg|
          count = @pub.lpush PUB_CHANNEL, msg
          LOGGER.debug "#{count} msg(s) in channel '#{PUB_CHANNEL}'" if count % 100 == 0
          return if Shadowcell::Feeder.stop?
        end
      end
    end

    # blatantly stolen from sidekiq...
    #
    def self.stop!
      @stop = true
    end
    def self.stop?
      @stop
    end

  end
end
