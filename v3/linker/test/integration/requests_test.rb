$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), ".."))
require 'helper'
require 'test_client'
require 'net/http'
require 'mongo'

class TestRequest < Test::Unit::TestCase
  include Mongo

  def setup
    @db = Connection.new.db('hoccer_v3')
    @db.collection('clients').remove
  end

  def teardown
    @db.collection('clients').remove
    @db.collection('environments').remove
  end

  test "registering clients" do
    db = Connection.new.db('hoccer_v3')

    client_1 = TestClient.new
    client_1.register

    client_2 = TestClient.new
    client_2.register

    assert_not_nil client_1.uuid
    assert_not_nil client_2.uuid
    assert client_1.uuid != client_2.uuid

    assert_equal 2, @db.collection('clients').find.to_a.size
  end

  test "updating the environment" do
    client = TestClient.create
    assert_not_nil client.uuid

    response = client.update_environment({
      :gps => { :latitude => 32.22, :longitude => 88.74 }
    })

    assert_equal 1, @db.collection('environments').find.to_a.size

    assert_equal "200", response.header.code
    client.delete_environment
  end

  test "lonesome client tries to share" do
    client = TestClient.create
    client.update_environment({
      :gps => { :latitude => 12.22, :longitude => 18.74 }
    })
    client.share( "pass", {:inline => "hello"} )

    assert_equal "204", client.follow_redirect.header.code
  end

  #test "lonesome client tries to receive" do
  #  client = TestClient.create
  #  client.update_environment({
  #    :gps => { :latitude => 52.22, :longitude => 28.74 }
  #  })

  #  assert_equal "204", client.receive( "pass" ).header.code

  #  client.delete_environment
  #end

  #test "two clients one share but no receive action" do
  #  client_1 = TestClient.create
  #  client_2 = TestClient.create

  #  client_1.update_environment({
  #    :gps => { :latitude => 12.22, :longitude => 18.74 }
  #  })

  #  client_2.update_environment({
  #    :gps => { :latitude => 12.22, :longitude => 18.74 }
  #  })

  #  client_1.share( "pass", {:inline => "foobar"} )

  #  start_time = Time.now
  #  response = client_1.follow_redirect
  #  time_taken = Time.now - start_time

  #  assert time_taken >= 7, "Should timeout after 7 seconds"
  #  assert_equal "204", response.header.code

  #  client_1.delete_environment
  #  client_2.delete_environment
  #end

  #test "two clients one receive but no share action" do
  #  client_1 = TestClient.create
  #  client_2 = TestClient.create

  #  client_1.update_environment({
  #    :gps => { :latitude => 12.22, :longitude => 18.74 }
  #  })

  #  client_2.update_environment({
  #    :gps => { :latitude => 12.22, :longitude => 18.74 }
  #  })

  #  start_time = Time.now
  #  response = client_1.receive("pass")
  #  time_taken = Time.now - start_time

  #  assert time_taken >= 7, "Should timeout after 7 seconds"
  #  assert_equal "204", response.header.code

  #  client_1.delete_environment
  #  client_2.delete_environment
  #end

  #test "two clients sharing and then receiving successfully" do
  #  client_1 = TestClient.create
  #  client_2 = TestClient.create

  #  client_1.update_environment({
  #    :gps => { :latitude => 12.22, :longitude => 18.74 }
  #  })

  #  client_2.update_environment({
  #    :gps => { :latitude => 12.22, :longitude => 18.74 }
  #  })

  #  client_1.share( "pass", {:inline => "foobar"} )
  #  assert_equal "204", client_1.follow_redirect.header.code

  #  expected = "[{\"inline\":\"foobar\"}]"
  #  assert_equal expected, client_2.receive( "pass" ).body

  #  client_1.delete_environment
  #  client_2.delete_environment
  #end

  #test "two clients receiving and then sharing successfully" do
  #  client_1 = TestClient.create
  #  client_2 = TestClient.create

  #  client_1.update_environment({
  #    :gps => { :latitude => 12.22, :longitude => 18.74 }
  #  })

  #  client_2.update_environment({
  #    :gps => { :latitude => 12.22, :longitude => 18.74 }
  #  })

  #  expected = "[{\"inline\":\"foobar\"}]"
  ##  assert_equal expected, client_2.receive( "pass" ).body

  #  t1 = Thread.new do
  #    client_2.receive_unthreaded("pass")
  #  end

  #  t2 = Thread.new do
  #    client_1.share("pass", {:inline => "foobar"})
  #    client_1.follow_redirect_unthreadded
  #  end

  #  client_2_response = t2.value
  #  client_1_response = t1.value

  #  assert_equal "200", client_1_response.header.code
  #  assert_equal "200", client_2_response.header.code

  #  expected = "[{\"inline\":\"foobar\"}]"
  #  assert_equal expected, client_2_response.body

  #  client_1.delete_environment
  #  client_2.delete_environment
  #end

end
