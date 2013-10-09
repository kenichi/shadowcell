module Shadowcell
  class Profiler < HCifiedActor

    GL_BASE_URL = 'https://api.geoloqi.com/1/'.freeze
    PROFILE_URL = (GL_BASE_URL + 'user/info/%s').freeze

    def profile user_id
      header = {'Authorization' => 'Shadow ' + CONFIG['geoloqi']['master_secret']}
      r = warn_if_time_over 1.0, "profile (#{user_id})" do
        JSON.parse @hc.get(PROFILE_URL % user_id, nil, header).body
      end
      LOGGER.debug "got geoloqi profile (#{user_id})"
      r
    end

  end
end
