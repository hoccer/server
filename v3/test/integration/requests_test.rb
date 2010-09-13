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

  test "two clients only one action" do

  end

end
