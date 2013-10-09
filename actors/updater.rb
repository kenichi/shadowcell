module Shadowcell
  class Updater < HCifiedActor

    BASE_URL = 'https://geotrigger.arcgis.com/device/update'.freeze

    def update token, tags = []
      header = {
        'Authorization' => 'Bearer ' + token,
        'Content-Type' => 'application/json'
      }
      params = {addTags: tags}
      @hci.post BASE_URL, params, header
      LOGGER.debug "updated device with:\n#{params}"
    end

  end
end
