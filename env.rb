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
    feeder.async.feed

    eater = Eater.new

      eater.flusher = Flusher.new
      eater.liaison = Liaison.new
      eater.poster = Poster.new
      eater.refresher = Refresher.new

      eater.liaison.profiler = Profiler.new
      eater.liaison.registrar = Registrar.new
      eater.liaison.updater = Updater.new

    eater.async.eat

  end

  class RedisifiedActor
    include Celluloid
    def initialize
      @redis = Shadowcell.redis_for host: CONFIG['redis']['host'],
                                    port: CONFIG['redis']['port']
    end
  end

  class HCifiedActor
    include Celluloid
    def initialize
      @hc = HTTPClient.new
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
