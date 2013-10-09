module Shadowcell
  class Registrar < HCifiedActor

    REGISTER_URL = (AGO_BASE_URL + 'oauth2/registerDevice').freeze

    def register client_id
      r = JSON.parse @hc.post(REGISTER_URL,
                              AGO_PARAMS.merge(client_id: client_id)).body
      r['deviceToken']['expires_at'] =
        Time.at(Time.now.to_i + r['deviceToken']['expires_in']).to_i
      r
    end

  end
end
