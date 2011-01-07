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

  def last_json_response
    if last_response.body
      JSON.parse last_response.body, {:symbolize_names => true}
    end
  rescue
    last_response.body
  end

  def test_default_route
    get '/'
    assert_equal "I'm the grouper!", last_response.body
  end

  def test_getting_no_body_error
    put "/clients/#{UUID.generate}/environment"
    assert_equal "JSON::ParserError: A JSON text must at least contain two octets!\n", last_response.body
  end

  def test_getting_emtpy_environment_error
    put "/clients/#{UUID.generate}/environment", {}.to_json
    assert_equal ({:message => "nothing", :quality => 0}), last_json_response
  end

  def test_getting_empty_environment_error_even_if_keys_exist
    put "/clients/#{UUID.generate}/environment", 
        {:wifi => {}, :network => {}, :gps => {}}.to_json
    assert_equal ({:message => "nothing", :quality => 0}), last_json_response
  end

end
