module Shadowcell
  class Profiler < HCifiedActor

    GL_BASE_URL = 'https://api.geoloqi.com/1/'.freeze
    PROFILE_URL = (GL_BASE_URL + 'user/info/%s').freeze

    def profile user_id
      header = {'Authorization' => 'Shadow ' + CONFIG['geoloqi']['master_secret']}
      r = JSON.parse @hci.get(PROFILE_URL % user_id, nil, header).body
      LOGGER.debug "geoloqi profile:\n#{r}"
      r
    end

  end
end
