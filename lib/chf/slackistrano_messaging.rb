module Chf
  class SlackistranoMessaging < Slackistrano::Messaging::Base
    def channels_for(action)
      channels = if fetch(:stage).to_s == "production"
        ["#digital-general"]
      else
        ["#{}digital-technical"]
      end
      if action == :failed
        channels << "#digital-technical"
      end
      channels.uniq
    end


    def username
      "Deploy Notification"
    end
  end
end
