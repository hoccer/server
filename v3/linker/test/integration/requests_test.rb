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
    response = client.share( "one-to-one", {:inline => "hello"} )
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

end
