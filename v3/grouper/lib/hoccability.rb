module Hoccer
  module Hoccability

    NO_DATA = {:quality => 0, :info => "no_data"}
    WRONG_DATA = {:quality => 0, :info => "bad_data"}
    OLD_DATA = {:quality => 1, :info => "old_data"}
    NO_TIMESTAMP = {:quality => 1, :info => "no_timestamp"}
    GOOD_DATA = {:quality => 3, :info => "good_data"}

    def self.analyze env
      status = {}

      status[:coordinates] = env.has_gps ? judge_coordinates(env[:gps]) : NO_DATA
      status[:wifi] = env.has_wifi ? judge_wifi(env[:wifi].with_indifferent_access) : NO_DATA

      status[:quality] = 0
      status[:quality] += 1 if status[:wifi][:quality] > 0
      status[:quality] += [status[:coordinates][:quality],2].min

      status[:devices] = env.group.count

      status
    end 

    def self.judge_coordinates gps
      return NO_TIMESTAMP unless gps[:timestamp]
      NO_DATA

      judge_timestamp(gps) or GOOD_DATA
    end

    def self.judge_wifi wifi
      return NO_DATA unless wifi[:bssids].class.equal? Array
      return WRONG_DATA unless wifi[:bssids].inject(true) {|valid, bssid| 
        bssid.match /^(\S{1,2}:\S{1,2}:\S{1,2}:\S{1,2}:\S{1,2}:\S{1,2})?$/
      }

      judge_timestamp(wifi) or GOOD_DATA
    end

    def self.judge_timestamp info
      return NO_TIMESTAMP unless info[:timestamp]
      return OLD_DATA unless info[:timestamp] > (Time.now - 2.minutes).to_i

      nil
    end
  end
end
