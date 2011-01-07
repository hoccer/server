$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), ".."))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__)))

require 'lib/grouper.rb'
require 'test/unit'
require 'rack/test'

ENV['RACK_ENV'] = 'test'

module Hoccer
  class TestGrouper < Test::Unit::TestCase
    include Rack::Test::Methods

    def app
      Grouper.new
    end

    def test_default_route
      get '/'
      assert_equal "I'm the grouper!", last_response.body
    end
  end
end
