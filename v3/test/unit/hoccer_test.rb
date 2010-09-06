$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), ".."))
require 'helper'

class TestHoccer < Test::Unit::TestCase
  include Sinatra::Async::Test::Methods

  def app
    @app ||= Hoccer::App.new
  end

  def setup
    Client.delete_all
    @client = Client.create
  end

  test "registering a new client" do
    post "clients"
    assert_equal 303, last_response.status
    assert last_response.headers["Location"] =~ /\/clients\/[a-z0-9]/
  end

  test "client requests self_reference" do
    get "/clients/#{@client.uuid}"
    expected = "{\"uri\":\"/clients/#{@client.uuid}\"}"
    assert_equal expected, last_response.body
  end

  test "client requests self reference with malicious_uuid" do
    get "/clients/c7dde7f09bef012d8e37001f5bf1b5ba"
    assert_equal 412, last_response.status
  end

  test "client updates its environment without being grouped" do
    with_events do
      env = {:foo => "bar"}.to_json
      put "/clients/#{@client.uuid}/environment", :json => env
      assert_async
      async_continue
      assert_equal 200, last_response.status
    end

    assert_not_nil  @client.environment
    assert_nil      @client.group_id
  end

end
