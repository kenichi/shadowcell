module Shadowcell
  class Updater < HCifiedActor

    BASE_URL = 'https://geotrigger.arcgis.com/device/update'.freeze

    def update token, tags = [], &block
      header = {
        'Authorization' => 'Bearer ' + token,
        'Content-Type' => 'application/json'
      }
      params = {addTags: tags}
      @hci.post BASE_URL, params, header
      LOGGER.debug "updated device with:\n#{params}"
      yield
    end

  end
end
