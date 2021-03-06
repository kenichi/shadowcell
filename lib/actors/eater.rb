module Shadowcell
  class Eater < RedisifiedActor
    extend Stoppable

    attr_accessor :liaison, :poster, :refresher

    TOKEN_EXPIRY_THRESHOLD = 60
    BRPOP_TIMEOUT = 1.0

    def initialize
      super
      @redis.set POST_COUNT_KEY, 0
    end

    def eat
      until Eater.stop? do
        if msg = @redis.brpop(PUB_CHANNEL, BRPOP_TIMEOUT)

          data = JSON.parse msg[1]

          # do we have an access token for this device?
          #
          if user_data = @redis.get("user-#{data['user_id']}")

            LOGGER.debug "have data (#{data['user_id']})"

            user_data = JSON.parse user_data
            expires_in = user_data['ago']['deviceToken']['expires_at'].to_i - Time.now.to_i

            # is the token about to expire?
            #
            if expires_in < TOKEN_EXPIRY_THRESHOLD

              LOGGER.debug "about to expire: #{expires_in} (#{data['user_id']})"

              # put this update in the list
              #
              queue_msg_for_later data, msg

              # start a refresh token job
              #
              aci = CONFIG['ago']['apps'][data['client_id'].to_i]['client_id']
              rt = user_data['ago']['deviceToken']['refresh_token']

              @refresher.async.refresh aci, rt, data['user_id'], user_data

            # good to go: post the update
            #
            else

              LOGGER.debug "have token, posting (#{data['user_id']})"
              at = user_data['ago']['deviceToken']['access_token']
              @poster.async.post at, data

            end

          # no token...
          #
          else

            # put this update in the list
            #
            if queue_msg_for_later(data, msg) == 1

              LOGGER.debug "first update, handing to liaison (#{data['user_id']})"

              # if it's the first one in the list, start a registration
              #
              @liaison.async.liaise data

            end

          end

        end
      end
      LOGGER.error "the EATER has STOPPED eating!!!"
    end

    def queue_msg_for_later data, msg
      key = "user-locations-#{data['user_id']}"
      count = @redis.lpush key, msg[1]
      LOGGER.debug "#{count} jobs in #{key}" if count % 10 == 0
      count
    end

  end
end
