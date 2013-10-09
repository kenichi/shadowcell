module Shadowcell
  class Updater < HCifiedActor

    BASE_URL = 'https://geotrigger.arcgis.com/device/update'.freeze

    def update token, tags = [], user_id
      header = {
        'Authorization' => 'Bearer ' + token,
        'Content-Type' => 'application/json'
      }
      params = {addTags: tags}
      r = JSON.parse @hc.post(BASE_URL, params, header).body
      LOGGER.debug "updated device (#{user_id})"
    end

  end
end
