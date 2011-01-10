module Hoccer
  class Hoccability

    NO_DATA = {:quality => 0, :info => "no_data"}

    def self.analyze env
      status = {}

      status[:coordinates] = NO_DATA unless env.has_gps or env.has_network
      status[:wifi] = NO_DATA unless env.has_wifi

      status[:quality] = status[:coordinates][:quality]
      status[:devices] = env.group.count

      status
    end 

  end
end
