$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), ".."))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__)))

require 'lib/grouper.rb'
require 'test/unit'
require 'rack/test'
require 'helper'

ENV['RACK_ENV'] = 'test'

class TestGrouper < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Hoccer::Grouper.new
  end

  def test_default_route
    get '/'
    assert_equal "I'm the grouper!", last_response.body
  end

  def test_getting_emtpy_environment_error
    put "/clients/#{UUID.generate}/environment"
    assert_equal "JSON::ParserError: A JSON text must at least contain two octets!\n", last_response.body
  end
end
