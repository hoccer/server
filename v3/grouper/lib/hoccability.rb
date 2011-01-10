module Hoccer
  module Hoccability

    NO_DATA = {:quality => 0, :info => "no_data"}
    BAD_DATA = {:quality => 0, :info => "bad_data"}
    GOOD_DATA = {:quality => 3, :info => "good_data"}

    def self.analyze env
      status = {}

      status[:coordinates] = env.has_gps ? judge_coordinates(env[:gps]) : NO_DATA
      status[:wifi] = env.has_wifi ? judge_wifi(env[:wifi].with_indifferent_access[:bssids]) : NO_DATA

      status[:quality] = 0
      status[:quality] += 1 if status[:wifi][:quality] > 0
      status[:quality] += [status[:coordinates][:quality],2].min

      status[:devices] = env.group.count

      status
    end 

    def self.judge_coordinates gps
      NO_DATA
    end

    def self.judge_wifi bssids
      return NO_DATA unless bssids.class.equal? Array
      return BAD_DATA unless bssids.inject(true) {|valid, bssid| bssid.match /^(\S{1,2}:\S{1,2}:\S{1,2}:\S{1,2}:\S{1,2}:\S{1,2})?$/}
      
      GOOD_DATA
    end

  end
end
