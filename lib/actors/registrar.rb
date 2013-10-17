module Shadowcell
  class Registrar < HCifiedActor

    REGISTER_URL = (AGO_BASE_URL + 'oauth2/registerDevice').freeze
    AVG_KEYS = [
      'registrar'.freeze,
      'registrar_count'.freeze
    ]

    def register client_id, user_id
      r = warn_if_time_over 1.0, "register" do
        JSON.parse @hc.post(REGISTER_URL, AGO_PARAMS.merge(client_id: client_id)).body
      end
      r['deviceToken']['expires_at'] =
        Time.at(Time.now.to_i + r['deviceToken']['expires_in']).to_i
      LOGGER.debug "registered device (#{user_id})"
      r
    end

  end
end
