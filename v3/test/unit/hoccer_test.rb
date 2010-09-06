$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", ".."))
require 'test/unit'
require 'eventmachine'
require 'sinatra/async'
require "sinatra/async/test"
require 'hoccer'

class TestHoccer < Test::Unit::TestCase
  include Sinatra::Async::Test::Methods

  def app
    @app ||=Hoccer::App.new
  end

  def app= sin_app
    @app = sin_app
  end

  def test_my_tests
    assert true
  end

  def test_basic_route
    get "high"
    assert_async
  end

  def test_creating_new_uuid
    post "clients"
    assert_equal 303, last_response.status
    assert last_response.headers["Location"] =~ /\/clients\/[a-z0-9]/
  end

  def test_client_self_reference
    post "clients"
    my_uuid = last_response.headers["Location"].match(/[a-z0-9]+$/)[0]

    get "/clients/#{my_uuid}"
    assert_equal "yay", last_response.body
  end

  def test_self_reference_with_malicious_uuid
    get "/clients/c7dde7f09bef012d8e37001f5bf1b5ba"
    assert_equal 412, last_response.status
  end

  def test_putting_the_environment
    #post "clients"
    #my_uuid = last_response.headers["Location"].match(/[a-z0-9]+$/)[0]
    l_app = app
    get "/high"
    assert_async
    app = l_app
    async_continue
  end

end
