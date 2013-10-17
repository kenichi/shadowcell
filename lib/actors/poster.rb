module Shadowcell
  class Poster < UberActor

    LU_URL = 'https://geotrigger.arcgis.com/location/update'.freeze
    AVG_KEYS = [
      'poster'.freeze,
      'poster_count'.freeze
    ]

    def post access_token, data
      header = {
        'Authorization' => 'Bearer ' + access_token,
        'Content-Type' => 'application/json'
      }
      params = {
        locations: [
          {
            timestamp: data['date'],
            latitude: data['latitude'],
            longitude: data['longitude'],
            accuracy: data['horizontal_accuracy'],
            battery: data['battery'],
            speed: data['speed'],
            trackingProfile: 'adaptive'
          }
        ]
      }
      LOGGER.debug "posting location update (#{data['user_id']})"
      warn_if_time_over 1.0, "posting" do
        JSON.parse @hc.post(LU_URL, params.to_json, header).body
      end
      @redis.incr POST_COUNT_KEY
    end

  end
end
