$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), ".."))
require 'helper'
require 'linccer_client'
require 'mongo'
require 'net/http'
require 'ruby-debug'

class TestRequest < Test::Unit::TestCase

  def setup
    db = Mongo::Connection.new.db('hoccer_development')
    coll = db.collection('environments')
    coll.remove
    
    messages = db.collection('messages')
    coll.remove
  end

  test "create unique uuids in test client" do
    client1 = LinccerClient.new {}
    client2 = LinccerClient.create
  
    assert_not_equal client1.uuid, client2.uuid
  end
  
  test "updating the environment" do
    client = LinccerClient.new :host => "127.0.0.1", :port => 9292
    assert_not_nil client.uuid
  
    response = client.update_environment({
      :gps => { :latitude => 32.22, :longitude => 88.74, :accuracy => 100 }
    })
  
    assert response
    client.delete_environment
  end
  
  test "lonesome client tries to share" do
    client = LinccerClient.new :host => "127.0.0.1", :port => 9292
    client.update_environment({
      :gps => { :latitude => 12.22, :longitude => 18.74, :accuracy => 100 }
    })
    start_time = Time.now
    response = client.share( "one-to-one", {:inline => "hello"} )
    duration = Time.now - start_time < 0.1
  
    assert duration, "client should return immediatly, but it took #{duration}"
    assert_nil response
  
    client.delete_environment
  end
  
  test "lonesome client tries to receive" do
    client = LinccerClient.new :host => "127.0.0.1", :port => 9292
    client.update_environment({
      :gps => { :latitude => 52.22, :longitude => 28.74, :accuracy => 100 }
    })
  
    assert_nil client.receive( "one-to-one" )
  
    client.delete_environment
  end
  
  test "two clients one share but no receive action" do
    client_1 = LinccerClient.new :host => "127.0.0.1", :port => 9292
    client_1.update_environment({
      :gps => { :latitude => 12.22, :longitude => 18.74, :accuracy => 100 }
    })
  
    client_2 = LinccerClient.new :host => "127.0.0.1", :port => 9292
  
    client_2.update_environment({
      :gps => { :latitude => 12.22, :longitude => 18.74, :accuracy => 100 }
    })
  
    start_time = Time.now
    response = client_1.share( "one-to-many", {:inline => "foobar"} )
    time_taken = Time.now - start_time
  
    assert time_taken >= 2, "Should timeout after 7 seconds"
    assert_nil response
  
    client_1.delete_environment
    client_2.delete_environment
  end
  
  test "two clients one receive but no share action" do
    client_1 = LinccerClient.new :host => "127.0.0.1", :port => 9292
    client_2 = LinccerClient.new :host => "127.0.0.1", :port => 9292
  
    client_1.update_environment({
      :gps => { :latitude => 12.22, :longitude => 18.74, :accuracy => 100 }
    })
  
    client_2.update_environment({
      :gps => { :latitude => 12.22, :longitude => 18.74, :accuracy => 100 }
    })
  
    start_time = Time.now
    response = client_1.receive("one-to-one")
    time_taken = Time.now - start_time
  
    assert time_taken >= 2, "Should timeout after 2 seconds"
    assert_nil response
  
    client_1.delete_environment
    client_2.delete_environment
  end
  
  test "two clients sharing and then receiving successfully" do
    client_1 = LinccerClient.new :host => "127.0.0.1", :port => 9292
    client_2 = LinccerClient.new :host => "127.0.0.1", :port => 9292
  
    client_1.update_environment({
      :gps => { :latitude => 12.22, :longitude => 18.74, :accuracy => 100 }
    })
  
    client_2.update_environment({
      :gps => { :latitude => 12.22, :longitude => 18.74, :accuracy => 100}
    })
  
    t1 = Thread.new do
      client_1.share( "one-to-one", {:inline => "foobar"} )
    end
  
    sleep(0.1)
  
    t2 = Thread.new do
      client_2.receive( "one-to-one" )
    end
  
    client_1_response = t1.value
    client_2_response = t2.value
  
    expected = [ { "inline" => "foobar"} ]
    assert_equal expected, client_2_response
  
  end
  
  
  test "two clients receiving and then sharing successfully" do
    client_1 = LinccerClient.new :host => "127.0.0.1", :port => 9292
    client_2 = LinccerClient.new :host => "127.0.0.1", :port => 9292
  
    client_1.update_environment({
      :gps => { :latitude => 12.22, :longitude => 18.74, :accuracy => 100 }
    })
  
    client_2.update_environment({
      :gps => { :latitude => 12.22, :longitude => 18.74,:accuracy => 100 }
    })
  
    t1 = Thread.new do
      client_2.receive("one-to-one")
    end
    sleep(1)
    t2 = Thread.new do
      client_1.share("one-to-one", {:inline => "foobar"})
    end
  
    client_2_response = t2.value
    client_1_response = t1.value
  
    assert client_1_response
    assert client_2_response
  
    expected_2 = [{ "inline" => "foobar"}]
    assert_equal expected_2, client_2_response
  
    expexted_1 = [{"inline" => "foobar"}]
    assert_equal expexted_1, client_1_response
  
    client_1.delete_environment
    client_2.delete_environment
  end
  
  test "two clients with different modes do not pair" do
    client_1 = create_client
    client_2 = create_client
  
    t1 = Thread.new { client_2.receive("one-to-one") }
    t2 = Thread.new { client_1.share("one-to-many", {:inline => "foobar"}) }
  
    client_2_response = t2.value
    client_1_response = t1.value
  
    assert_nil client_1_response
    assert_nil client_2_response
  
    client_1.delete_environment
    client_2.delete_environment
  end
  
  test "sending and receiving in both directions" do
    client_1 = create_client
    client_2 = create_client
  
    t1 = Thread.new { client_2.receive("one-to-one") }
    t2 = Thread.new { client_1.share("one-to-one", {:inline => "foobar"}) }
  
    client_2_response = t2.value
    client_1_response = t1.value
  
    assert client_1_response
    assert client_2_response
  
    expected_2 =  [ { "inline" => "foobar"} ]
    assert_equal expected_2, client_2_response
  
    expexted_1 = [{"inline" =>"foobar"}]
    assert_equal expexted_1, client_1_response
  
    sleep(2)
  
    t1 = Thread.new { client_1.share("one-to-one", {:inline => "buubaa"}) }
    t2 = Thread.new { client_2.receive("one-to-one") }
  
    client_2_response = t2.value
    client_1_response = t1.value
  
    assert client_1_response
    assert client_2_response
  
    expected_2 = [{"inline" => "buubaa"}]
    assert_equal expected_2, client_2_response
  
    expexted_1 = [{"inline" => "buubaa"}]
    assert_equal expexted_1, client_1_response
  
    client_1.delete_environment
    client_2.delete_environment
  end
  
  test "updating environment" do
    client = create_client
    client.update_environment(
        :gps => { :timestamp => 1289456, :latitude => 12.22, :longitude => 18.74, :accuracy => 100 }
    )
  end
  
  test "grouping and notifying clients" do
    client_1 = create_client
  
    t1 = Thread.new { client_1.peek }
    response = t1.value
    t1 = Thread.new { client_1.peek response["timestamp"] }
    
    client_2 = create_client
    sleep 1
    response = t1.value
    
    assert_equal 2, response["messages"].first["group"].count
    response_2 = client_2.peek
    assert_equal 2, response_2["messages"].first["group"].count
  end
  
  test "grouping and notifying clients with waiting" do
    client_1 = create_client
  
    t1 = Thread.new { client_1.peek }
    response = t1.value
    t1 = Thread.new { client_1.peek response["timestamp"] }
    
    sleep 10
    client_2 = create_client
    
    response = t1.value
    assert_equal 2, response["messages"].first["group"].count
  end
  
  test "not returning when group has no update" do
    client_1 = create_client
    client_2 = create_client
      
    t1 = Thread.new { client_1.peek }
    response = t1.value
    assert_equal 2, response["messages"].first["group"].count
    
    t2 = Thread.new { client_1.peek response["timestamp"]}
    sleep 3
    client_3 = create_client
    
    response_2 = t2.value
    assert_equal 3, response_2["messages"].first["group"].count
  end
  
  test "returning when client is deleted" do
    client_1 = create_client
    client_2 = create_client
    
    t1 = Thread.new { client_1.peek }
    response = t1.value
    
    t2 = Thread.new { client_1.peek( response["timestamp"] ) }
    client_2.delete_environment
    
    response_2 = t2.value
    assert_equal 1, response_2["messages"].first["group"].count
  end
  
  test "message passing" do
    client_1 = create_client
    client_2 = create_client
    
    t1 = Thread.new { client_1.get_messages }
    sleep(0.5)
    client_2.post_message( client_1.uuid, { :hello => "robert" } )
    
    response = t1.value
        
    assert_equal 1, response["messages"].size
    assert_equal "robert", response["messages"][0]["hello"]    
    
    t2 = Thread.new { client_1.get_messages response[ "timestamp" ] }
    client_2.post_message( client_1.uuid, { :hello => "john" } )
    response_2 = t2.value
    
    assert_equal 1, response_2["messages"].size
    assert_equal "john", response_2["messages"][0]["hello"]
  end
  
  test "getting messages after delay" do
    client_1 = create_client
    client_2 = create_client
    
    t1 = Thread.new { client_1.get_messages }
    sleep(0.5)
    client_2.post_message( client_1.uuid, { :hello => "robert" } )
    
    response = t1.value
    
    assert_equal 1, response["messages"].size
    assert_equal "robert", response["messages"][0]["hello"]    
    
    client_2.post_message( client_1.uuid, { :hello => "john" } )
    
    sleep(3)
    response_2 = client_1.get_messages response[ "timestamp" ] 
    
    assert_equal 1, response_2["messages"].size
    assert_equal "john", response_2["messages"][0]["hello"]
  end
  
  test "getting messages for grouping" do
    client_1 = create_client
  
    t1 = Thread.new { client_1.peek }
    response = t1.value
    
    t1 = Thread.new { client_1.peek response["timestamp"] }
    
    client_2 = create_client
    sleep 1
    response = t1.value
    
    assert_equal "regrouped", response["messages"].first["type"]
    assert_equal 2, response["messages"].first["group"].count
    response_2 = client_2.peek
    
    assert_equal "regrouped", response["messages"].first["type"]
    assert_equal 2, response["messages"].first["group"].count
  end
  
  test "message about action" do
    client_1 = create_client
    client_2 = create_client
    sleep 0.5
    
    response = client_1.peek
    
    t = Thread.new { client_1.peek( response["timestamp"] ) }
    sleep 0.2
    t2 = Thread.new { client_2.share("one-to-many", { :hello => "world" }) }
    
    response_2 = t.value
    
    assert_equal "action", response_2["messages"].first["type"]
  end
  
  
end
