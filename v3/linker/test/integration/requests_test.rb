$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), ".."))
require 'helper'
require 'test_client'
require 'net/http'

class TestRequest < Test::Unit::TestCase

  test "registering clients" do
    client_1 = TestClient.new
    client_1.register

    client_2 = TestClient.new
    client_2.register

    assert_not_nil client_1.uuid
    assert_not_nil client_2.uuid
    assert client_1.uuid != client_2.uuid
    client_1.delete_environment
    client_2.delete_environment
  end

  test "updating the environment" do
    client = TestClient.create
    assert_not_nil client.uuid

    response = client.update_environment({
      :gps => { :latitude => 32.22, :longitude => 88.74 }
    })

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

    client.delete_environment
  end

  test "lonesome client tries to receive" do
    client = TestClient.create
    client.update_environment({
      :gps => { :latitude => 52.22, :longitude => 28.74 }
    })

    assert_equal "204", client.receive( "pass" ).header.code

    client.delete_environment
  end

  test "two clients one share but no receive action" do
    client_1 = TestClient.create
    client_2 = TestClient.create

    client_1.update_environment({
      :gps => { :latitude => 12.22, :longitude => 18.74 }
    })

    client_2.update_environment({
      :gps => { :latitude => 12.22, :longitude => 18.74 }
    })

    client_1.share( "pass", {:inline => "foobar"} )

    start_time = Time.now
    response = client_1.follow_redirect
    time_taken = Time.now - start_time

    assert time_taken >= 7, "Should timeout after 7 seconds"
    assert_equal "204", response.header.code

    client_1.delete_environment
    client_2.delete_environment
  end

  test "two clients one receive but no share action" do
    client_1 = TestClient.create
    client_2 = TestClient.create

    client_1.update_environment({
      :gps => { :latitude => 12.22, :longitude => 18.74 }
    })

    client_2.update_environment({
      :gps => { :latitude => 12.22, :longitude => 18.74 }
    })

    start_time = Time.now
    response = client_1.receive("pass")
    time_taken = Time.now - start_time

    assert time_taken >= 7, "Should timeout after 7 seconds"
    assert_equal "204", response.header.code

    client_1.delete_environment
    client_2.delete_environment
  end

  test "two clients sharing and then receiving successfully" do
    client_1 = TestClient.create
    client_2 = TestClient.create

    client_1.update_environment({
      :gps => { :latitude => 12.22, :longitude => 18.74 }
    })

    client_2.update_environment({
      :gps => { :latitude => 12.22, :longitude => 18.74 }
    })

    t1 = Thread.new do
      client_1.share( "pass", {:inline => "foobar"} )
      client_1.follow_redirect_unthreadded
    end

    sleep(0.1)

    t2 = Thread.new do
      client_2.receive( "pass" )
    end

    client_1_response = t1.value
    client_2_response = t2.value

    expected = "[{\"inline\":\"foobar\"}]"
    assert_equal expected, client_2_response.body

  end

  test "two clients receiving and then sharing successfully" do
    client_1 = TestClient.create
    client_2 = TestClient.create

    client_1.update_environment({
      :gps => { :latitude => 12.22, :longitude => 18.74 }
    })

    client_2.update_environment({
      :gps => { :latitude => 12.22, :longitude => 18.74 }
    })

    t1 = Thread.new do
      client_2.receive_unthreaded("pass")
    end

    t2 = Thread.new do
      client_1.share("pass", {:inline => "foobar"})
      client_1.
    end

    client_2_response = t2.value
    client_1_response = t1.value

    assert_equal "200", client_1_response.header.code
    assert_equal "200", client_2_response.header.code

    expected_2 = "{\"receiver\":1}"
    assert_equal expected_2, client_2_response.body

    expexted_1 = "[{\"inline\":\"foobar\"}]"
    assert_equal expexted_1, client_1_response.body
    client_1_response.body

    client_1.delete_environment
    client_2.delete_environment
  end

end