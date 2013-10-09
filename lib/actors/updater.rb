module Shadowcell
  class Updater < HCifiedActor

    BASE_URL = 'https://geotrigger.arcgis.com/device/update'.freeze

    def update token, tags = [], user_id
      header = {
        'Authorization' => 'Bearer ' + token,
        'Content-Type' => 'application/json'
      }
      params = {addTags: tags}
      r = warn_if_time_over 1.0, "update" do
        JSON.parse @hc.post(BASE_URL, params, header).body
      end
      LOGGER.debug "updated device (#{user_id})"
    end

  end
end
