$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), ".."))
require 'helper'
require 'linccer_client'
require 'mongo'
require 'net/http'

class TestOneToOne < Test::Unit::TestCase

  def setup
    db = Mongo::Connection.new.db('hoccer_development')
    coll = db.collection('environments')
    coll.remove
  end

  # test 'two in group - one sender - one receiver' do
  #   client_1 = create_client
  #   client_2 = create_client
  #  
  #   start_time = Time.now
  #   t2 = Thread.new { client_2.receive("one-to-one") }
  #   t1 = Thread.new { client_1.share("one-to-one", { :inline => "foobar" }) }
  #  
  #   client_2_response = t2.value
  #   client_1_response = t1.value
  #  
  #   duration = Time.now - start_time
  #  
  #   assert client_1_response
  #   assert client_2_response
  #   assert duration < 0.1, "clients should pair immediatly"
  #  
  #   expected = [ { "inline" => "foobar"} ]
  #   assert_equal expected, client_1_response
  #   assert_equal expected, client_2_response
  #  
  #   client_1.delete_environment
  #   client_2.delete_environment
  # end
  #  
  # test 'three in group - two sender - one receiver' do
  #   client_1 = create_client
  #   client_2 = create_client
  #   client_3 = create_client
  #  
  #   t2 = Thread.new {
  #     begin
  #       client_2.share("one-to-one", { :inline => "barbaz"})
  #       fail "should have thrown a 409 - Conflict Exception"
  #     rescue => e
  #     end
  #   }
  #  
  #   t1 = Thread.new {
  #     begin
  #       client_1.share("one-to-one", { :inline => "foobar" })
  #       fail "should have thrown a 409 - Conflict Exception"
  #     rescue => e
  #     end
  #   }
  #  
  #   t3 = Thread.new { sleep(1); client_3.receive("one-to-one") }
  #  
  #   client_3_response = t3.value
  #   client_2_response = t2.value
  #   client_1_response = t1.value
  #   assert_nil client_3_response
  #  
  #   client_1.delete_environment
  #   client_2.delete_environment
  #   client_3.delete_environment
  # end
  #  
  # test 'three in group - one sender - two receiver' do
  #   client_1 = create_client
  #   client_2 = create_client
  #   client_3 = create_client
  #  
  #   begin
  #     t2 = threaded_receive(client_2, "one-to-one")
  #     t1 = threaded_share(client_1, "one-to-one", { :inline => "foobar" } )
  #     sleep(1)
  #     t3 = threaded_receive(client_3, "one-to-one")
  #     fail "should have thrown a '409 - Conflict' exception"
  #     client_3_response = t3.value
  #     client_2_response = t2.value
  #     client_1_response = t1.value
  #   rescue
  #   end
  #  
  #   assert_equal nil, client_1_response
  #   assert_equal nil, client_2_response
  #   assert_equal nil, client_3_response
  #  
  #   client_1.delete_environment
  #   client_2.delete_environment
  #   client_3.delete_environment
  # end
  #  
  #  
  # test 'three in group - one sender - one receiver' do
  #   client_1 = create_client
  #   client_2 = create_client
  #   client_3 = create_client
  #  
  #   t2 = Thread.new { client_2.receive("one-to-one") }
  #   t1 = Thread.new { client_1.share("one-to-one", { :inline => "foobar" }) }
  #  
  #   client_2_response = t2.value
  #   client_1_response = t1.value
  #  
  #   assert client_1_response
  #   assert client_2_response
  #  
  #   client_1.delete_environment
  #   client_2.delete_environment
  #   client_3.delete_environment
  # end
end
