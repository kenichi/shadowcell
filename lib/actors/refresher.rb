module Shadowcell
  class Refresher < UberActor

    REFRESH_URL = (AGO_BASE_URL + 'oauth2/token').freeze
    GRANT_TYPE = 'refresh_token'.freeze
    AVG_KEYS = [
      'refresher'.freeze,
      'refresher_count'.freeze
    ]

    def refresh client_id, refresh_token, user_id, user_data
      params = {
        client_id: client_id,
        grant_type: GRANT_TYPE,
        refresh_token: refresh_token
      }
      r = warn_if_time_over 1.0, "refresh" do
        JSON.parse @hc.post(REFRESH_URL, AGO_PARAMS.merge(params)).body
      end
      user_data['ago']['deviceToken']['access_token'] = r['access_token']
      user_data['ago']['deviceToken']['expires_at'] = 
        Time.at( Time.now.to_i + r['expires_in'].to_i ).to_i
      @redis.set "user-#{user_id}", user_data.to_json
    end

  end
end
