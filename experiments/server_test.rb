#!/usr/bin/env ruby

require "rubygems"
require "active_support"
require "test/unit"

require "client"

class ServerTest < Test::Unit::TestCase

  def initialize what
    super what
    @data = "{...}"
  end

  def test_pairing_immediately
    puts @data
    sc = Client.new 33.324, 22.112, 100
    rc = Client.new 33.321, 22.115, 100

    st = Thread.new{sc.share :pass, @data}
    rt = Thread.new{rc.receive :pass}
    assert_equal @data, rt.value
  end

 # def test_pairing_one_after_another
 #   s = Client.new 33.324, 22.112, 100
 #   r = Client.new 33.321, 22.115, 100

 #   s.share :pass, @data
 #   assert_equal @data, (r.receive :pass)
 # end

 # def test_pairing_with_delayed_receive
 #   sc = Client.new 33.324, 22.112, 100
 #   rc = Client.new 33.321, 22.115, 100

 #   st = Thread.new{sc.share :pass, @data}
 #   rt = Thread.new{sleep 1; rc.receive :pass}
 #   assert_equal @data, rt.value
 # end

 # def test_pairing_with_delayed_send
 #   sc = Client.new 33.324, 22.112, 100
 #   rc = Client.new 33.321, 22.115, 100

 #   st = Thread.new{sleep 1; sc.share :pass, @data}
 #   rt = Thread.new{rc.receive :pass}
 #   assert_equal @data, rt.value
 # end

 # def test_no_pairing_because_distance_to_far
 #   s = Client.new 33.324, 22.122, 100
 #   r = Client.new 33.321, 22.115, 100

 #   assert_raise NoOneReceivedError do
 #     s.share :pass, @data
 #   end
 #   assert_raise NoOneSharedError do
 #     r.receive :pass
 #   end
 # end
end
