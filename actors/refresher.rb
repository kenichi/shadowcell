module Shadowcell
  class Refresher < UberActor

    REFRESH_URL = (AGO_BASE_URL + 'oauth2/token').freeze
    GRANT_TYPE = 'refresh_token'.freeze

    def refresh client_id, refresh_token, user_id, user_data
      params = {
        client_id: client_id,
        grant_type: GRANT_TYPE,
        refresh_token: refresh_token
      }
      user_data[:ago] = JSON.parse @hc.post(REFRESH_URL, AGO_PARAMS.merge(params)).body
      @redis.set "user-#{user_id}", user_data.to_json
    end

  end
end
