ENV['TZ'] = 'UTC'
Encoding.default_internal = 'UTF-8'

require 'celluloid'
require 'celluloid/io'
require 'celluloid/redis'
require 'redis'
require 'httpclient'
require 'yaml'
require 'json'
require 'logger'

module Shadowcell

  REDIS_TIMEOUT = 10
  SUB_CHANNEL = 'global-feed'.freeze
  PUB_CHANNEL = 'incoming-data'.freeze
  AGO_BASE_URL = 'https://www.arcgis.com/sharing/'.freeze
  AGO_PARAMS = {f: 'json'}.freeze

  CONFIG_FILE = 'config.yml'
  CONFIG = YAML.load_file(CONFIG_FILE) or raise "no #{CONFIG_FILE} found"

  LOGGER = Logger.new STDOUT
  LOGGER.level = Logger::WARN

  def self.redis_for opts = {}
    Redis.new timeout: REDIS_TIMEOUT,
              host: opts[:host],
              port: opts[:port],
              driver: :celluloid
  end

  def self.run

    feeder = Feeder.new
    eater = Eater.new

      eater.liaison = Liaison.new
      eater.poster = Poster.pool
      eater.refresher = Refresher.pool

      eater.liaison.flusher = Flusher.pool args: [eater]
      # eater.liaison.flusher.eater = eater

      eater.liaison.profiler = Profiler.pool
      eater.liaison.registrar = Registrar.pool
      eater.liaison.updater = Updater.pool

    feeder.async.feed
    eater.async.eat

  end

  module RedisActor
    def create_redis
      @redis = Shadowcell.redis_for host: CONFIG['redis']['host'],
                                    port: CONFIG['redis']['port']
    end
  end

  module HCActor
    def create_hc
      @hc = HTTPClient.new
    end
  end

  module Timer
    def warn_if_time_over threshold, thing, &block
      t = Time.now
      ret = yield
      t = (Time.now - t).to_f
      LOGGER.warn "#{t}s to #{thing}" if t > threshold
      ret
    end
  end
  
  class RedisifiedActor
    include Celluloid
    include RedisActor
    def initialize
      create_redis
    end
  end

  class HCifiedActor
    include Celluloid
    include HCActor
    include Timer
    def initialize
      create_hc
    end
  end

  class UberActor
    include Celluloid
    include RedisActor
    include HCActor
    include Timer
    def initialize
      create_redis
      create_hc
    end
  end

end

$: << File.expand_path('..', __FILE__)
require 'actors/eater'
require 'actors/feeder'
require 'actors/flusher'
require 'actors/liaison'
require 'actors/poster'
require 'actors/profiler'
require 'actors/refresher'
require 'actors/registrar'
require 'actors/updater'