ENV['TZ'] = 'UTC'
Encoding.default_internal = 'UTF-8'
require 'rubygems'
require 'bundler/setup'
Bundler.require

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
  LOGGER.level = Logger::DEBUG

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
      eater.poster = Poster.new
      eater.refresher = Refresher.new

      eater.liaison.flusher = Flusher.new
      eater.liaison.profiler = Profiler.new
      eater.liaison.registrar = Registrar.new
      eater.liaison.updater = Updater.new

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
    def initialize
      create_hc
    end
  end

  class UberActor
    include Celluloid
    include RedisActor
    include HCActor
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
