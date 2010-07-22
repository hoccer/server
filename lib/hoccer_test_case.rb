require 'log_replay'
require 'righttp'

class HoccerTestCase
  include Rig

  @@rewrite_table = {}

  def initialize logfile_path
    @logfile_path = logfile_path
  end

  def lookup request
    if request.log_entry =~ /Processing\sEventsController/
      if (client = @@rewrite_table[request.client_ip]) && request.request_id
        if client[:event_id]
          return client[:event_id][request.request_id]
        end
      end
    elsif request.log_entry =~ /Processing\sUploadsController/
      if (client = @@rewrite_table[request.client_ip]) && request.request_id
        if client[:upload_id]
          return client[:upload_id].values.first
        end
      end
    end
  end

  def run
    LogReplay::Request.each_with_timing(@logfile_path) do |replay_request|

      next if replay_request.log_entry =~ /peers/

      new_id = lookup(replay_request)

      if replay_request.path && new_id
        new_path = replay_request.path.gsub(replay_request.request_id, new_id)
      end

      request = HTTP.new(
        :host   => "localhost",
        :port   => "3000",
        :method => replay_request.request_method,
        :path   => new_path || replay_request.path,
        :params => replay_request.params
      )

      response = request.send

      if request.method == "POST"
        @@rewrite_table[replay_request.client_ip] ||= {}

        event_id = response[0].match(LogReplay::Request::LOCATION)[1]

        old_id   = replay_request.location.split("/").last

        @@rewrite_table[replay_request.client_ip].merge!(
          :event_id => { old_id => event_id }
        )
      end

      if request.method == "GET" && response[0] =~ /upload_uri/
        upload_uri = URI.parse( response[0].match(/\"upload_uri\"\:\"([a-z\/0-9\:]+)\"\,/)[1] )
        upload_id  = upload_uri.path.split("/").last

        @@rewrite_table[replay_request.client_ip].merge!(
          :upload_id  => { "" => upload_id }
        )
      end

      response_status = response[0].match(/(\d\d\d)/)[1]

      if response_status == replay_request.status
        puts "yes"
      else
        puts "fuck #{replay_request.status} expected but got #{response_status}"
      end

    end
  end

end

testcase = HoccerTestCase.new "/Users/hukl/Desktop/production.log"
testcase.run

