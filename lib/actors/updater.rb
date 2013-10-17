module Shadowcell
  class Updater < HCifiedActor

    attr_accessor :flusher

    BASE_URL = 'https://geotrigger.arcgis.com/device/update'.freeze
    AVG_KEYS = [
      'updater'.freeze,
      'updater_count'.freeze
    ]

    def initialize flusher = nil
      super()
      @flusher = flusher
    end

    def update token, tags = [], user_id
      header = {
        'Authorization' => 'Bearer ' + token,
        'Content-Type' => 'application/json'
      }
      params = {addTags: tags}
      r = warn_if_time_over 1.0, "update" do
        JSON.parse @hc.post(BASE_URL, params, header).body
      end
      LOGGER.debug "updated device (#{user_id})"

      @flusher.async.flush user_id
    end

  end
end
