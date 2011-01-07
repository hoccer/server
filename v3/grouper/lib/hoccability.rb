module Hoccer
  class Hoccability

    def self.status id, quality
      {:msg_id => id, :quality => quality}
    end

    def self.analyze env
      if not (env.has_gps or env.has_network or env.has_wifi)
        status :no_message_infos_provided, 0
      else
        status :unknown_error, 0
      end
    end 


  end
end
