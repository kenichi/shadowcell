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

  POST_COUNT_KEY = 'locations-updated'.freeze

  LOGGER = Logger.new STDOUT
  LOGGER.level = Logger::INFO

  def self.redis_for opts = {}
    Redis.new timeout: REDIS_TIMEOUT,
              host: opts[:host],
              port: opts[:port],
              driver: :celluloid
  end

  def self.run!

    @feeder = Feeder.new
    @eater = Eater.new

      @eater.poster = Poster.pool
      @eater.refresher = Refresher.pool

      @eater.liaison = Liaison.new

      @eater.liaison.profiler = Profiler.pool
      @eater.liaison.registrar = Registrar.pool

      @flusher = Flusher.new
      @eater.liaison.updater = Updater.pool args: [@flusher]

    @feeder.async.feed
    @eater.async.eat

    @reporter = Reporter.new.async.report

  end

  def self.stop!
    Feeder.stop!
    Eater.stop!
    Reporter.stop!
  end

  def self.average keys, time
    @redis ||= redis_for
    a = @redis.get(keys[0]).to_f || 0.0
    c = @redis.incr(keys[1]).to_i
    @redis.set keys[0], ((a * (c - 1)) + time) / c
  end

  module Stoppable
    def stop!
      @stop = true
    end
    def stop?
      @stop
    end
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
      ret, t = time &block
      LOGGER.warn "#{t}s to #{thing}" if t > threshold
      ret
    end

    def time &block
      t = Time.now
      ret = yield
      t = (Time.now - t).to_f
      Shadowcell.average self.class::AVG_KEYS, t
      return ret, t
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
require 'actors/reporter'
require 'actors/updater'
