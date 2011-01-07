module Hoccer
  class Hoccability

    def self.analyze env
      puts env.inspect
      if not (env.has_gps or env.has_network or env.has_wifi)
        {:message => "nothing", :quality => 0}
      else
        {:message => "nothing applies, your location is unknown!", :quality => 0}
      end
    end 

  end
end
