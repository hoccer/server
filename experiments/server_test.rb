#!/usr/bin/env ruby

require "rubygems"
require "active_support"
require "test/unit"

require "client"

class ServerTest < Test::Unit::TestCase

  def test_pairing_immediately
    sc = Client.new 33.324, 22.112, 100
    rc = Client.new 33.321, 22.115, 100

    data = "{...}"
    st = Thread.new{sc.send :pass, data}
    rt = Thread.new{rc.receive :pass}
    assert_equal data, rt.value
  end

  def test_pairing_with_delayed_receive
    sc = Client.new 33.324, 22.112, 100
    rc = Client.new 33.321, 22.115, 100

    data = "{...}"
    st = Thread.new{sc.send :pass, data}
    rt = Thread.new{sleep 1; rc.receive :pass}
    assert_equal data, rt.value
  end

  def test_pairing_with_delayed_send
    sc = Client.new 33.324, 22.112, 100
    rc = Client.new 33.321, 22.115, 100

    data = "{...}"
    st = Thread.new{sleep 1; sc.send :pass, data}
    rt = Thread.new{rc.receive :pass}
    assert_equal data, rt.value
  end

end
