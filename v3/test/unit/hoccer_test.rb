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

  def test_basic_route
    get "high"
    assert_async
    async_continue
  end

  def test_creating_new_uuid
    post "clients"
    assert_equal 303, last_response.status
    assert last_response.headers["Location"] =~ /\/clients\/[a-z0-9]/
  end

  def test_client_self_reference
    get "/clients/#{@client.uuid}"
    expected = "{\"uri\":\"/clients/#{@client.uuid}\"}"
    assert_equal expected, last_response.body
  end

  def test_self_reference_with_malicious_uuid
    get "/clients/c7dde7f09bef012d8e37001f5bf1b5ba"
    assert_equal 412, last_response.status
  end

  def test_putting_the_environment
    with_events do
      put "/clients/#{@client.uuid}/environment", :json => {:foo => "bar"}.to_json
      assert_async
      async_continue
      assert_equal 200, last_response.status
    end

    assert_not_nil @client.environment
  end

end
