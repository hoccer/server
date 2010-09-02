$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", ".."))
require 'test/unit'
require 'rack/test'
require 'sinatra/async'
require "sinatra/async/test"
require 'hoccer'

class TestHoccer < Test::Unit::TestCase
  include Sinatra::Async::Test::Methods

  def app
    Hoccer::App.new
  end

  def test_my_tests
    assert true
  end

  def test_my_app
    get "/client/uuid/action/id"
    assert_async
    async_continue
    assert_equal 200, last_response.status
  end
end
