#!/usr/bin/env ruby

require "rubygems"
require "active_support"
require "test/unit"

require "client"

class ServerTest < Test::Unit::TestCase

  def test_simple_pairing
    sc = Client.new 33.324, 22.112, 100
    rc = Client.new 33.321, 22.115, 100

    data = "{...}"
    st = Thread.new{sc.send :pass, data}
    rt = Thread.new{rc.receive :pass}
    assert_equal data, rt.value
  end

  def test_snappiness
    sc = Client.new 33.324, 22.112, 100
    rc = Client.new 33.321, 22.115, 100

    in_time = 0
    out_time = 0
    data = "{...}"
    st = Thread.new{
      out_time = Time.now
      sc.send :pass, data
    }
    rt = Thread.new{
      rc.receive :pass
      in_time = Time.now
    }
    st.join
    rt.join
    puts "snappiness is #{in_time - out_time}"
  end

end
