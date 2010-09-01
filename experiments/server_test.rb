#!/usr/bin/env ruby

require "rubygems"
require "active_support"
require "test/unit"

require "client"



def share lat, long, sleep_time, payload
  c = Client.new
  c.set_environment lat, long, 100

  sleep sleep_time

  c.send :pass, payload
end

def receive lat, long, sleep_time
  c = Client.new
  c.set_environment lat, long, 100

  sleep sleep_time

  c.receive :pass
end
  
class ServerTest < Test::Unit::TestCase

  def test_pairing

    data = "{...}"
    share = Thread.new{share 33.3, 22.1, 0, data}
    receive = Thread.new{receive 33.3, 22.1, 0}
    assert_equal data, receive.value
  end

end
