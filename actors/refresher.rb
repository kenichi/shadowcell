module Shadowcell
  class Refresher < HCifiedActor

    REFRESH_URL = (AGO_BASE_URL + 'oauth2/token').freeze
    GRANT_TYPE = 'refresh_token'.freeze

    def refresh client_id, refresh_token, &block
      params = {
        client_id: client_id,
        grant_type: GRANT_TYPE,
        refresh_token: refresh_token
      }
      yield JSON.parse @hc.post(REFRESH_URL, AGO_PARAMS.merge(params)).body
    end

  end
end
