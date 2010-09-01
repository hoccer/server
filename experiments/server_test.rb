#!/usr/bin/env ruby

require "rubygems"
require "active_support"
require "test/unit"

require "client"

def share lat, long, sleep_time, payload
  c = Client.new
  c.set_environment lat, long, 100

  sleep sleep_time

  start_sending = Time.now
  c.send :pass, payload
  start_sending
end

def receive lat, long, sleep_time
  c = Client.new
  c.set_environment lat, long, 100

  sleep sleep_time

  c.receive :pass
end
  
class ServerTest < Test::Unit::TestCase

  def test_simple_pairing
    data = "{...}"
    share = Thread.new{share 33.324, 22.112, 0, data}
    receive = Thread.new{receive 33.321, 22.115, 0}
    assert_equal data, receive.value
  end

  def test_snappiness
    data = "{...}"
    done_receiving = 0
    share = Thread.new{share 33.324, 22.112, 1, data}
    receive = Thread.new{
      receive 33.321, 22.115, 0
      done_receiving = Time.now
    }
    assert_not_equal data, receive.value
    puts "snappiness is #{done_receiving - share.value}"
  end

end
