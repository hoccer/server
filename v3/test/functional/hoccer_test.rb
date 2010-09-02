$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), ".."))

require 'test_helper'

class HoccerTest < Test::Unit::TestCase
  include Rack::Test::Methods

  test "that the tests are working" do

    get "/client/uuid"
    assert_async
    async_continue
  end
end
