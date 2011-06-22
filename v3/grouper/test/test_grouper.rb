$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), ".."))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__)))

require 'lib/grouper.rb'
require 'rubygems'
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

  def assert_empty_environment
    assert_equal 1, last_json_response[:hoccability][:devices], "lonely in the group"
    assert_equal 0, last_json_response[:hoccability][:quality]
    assert_equal Hoccability::NO_DATA, last_json_response[:hoccability][:coordinates]
    assert_equal Hoccability::NO_DATA, last_json_response[:hoccability][:wifi]
  end

  def test_getting_emtpy_environment_error
    put "/clients/#{UUID.generate}/environment", {}.to_json
    assert_empty_environment
  end

  def test_getting_empty_environment_error_if_only_the_keys_exist
    put "/clients/#{UUID.generate}/environment", 
        {:wifi => {}, :network => {}, :gps => {}}.to_json
    assert_empty_environment
  end

  def test_getting_if_only_the_keys_exist
    put "/clients/#{UUID.generate}/environment", 
        {:wifi => {}, :network => {}, :gps => {}}.to_json
    assert_empty_environment
  end

  def test_getting_lonley_client_error
    put "/clients/#{UUID.generate}/environment", 
        {:wifi => {}, :network => {}, :gps => {}}.to_json
    assert_empty_environment
  end

  def test_getting_bssid_feedback
    put "/clients/#{UUID.generate}/environment", 
        {:wifi => 
          {:bssids => ["00:22:3f:11:5e:5d","00:26:4d:72:cc:90"], 
           :timestamp => Time.now.to_i - 10.seconds}
        }.to_json

    assert_equal Hoccability::GOOD_DATA, last_json_response[:hoccability][:wifi]
    assert_equal 1, last_json_response[:hoccability][:quality], "overall quality not so good because only wifi provided"
  end

  def test_getting_maximal_quality_feedback
    put "/clients/#{UUID.generate}/environment", 
        {:wifi => 
          {:bssids => ["00:22:3f:11:5e:5d","00:26:4d:72:cc:90"], 
           :timestamp => Time.now.to_i - 10.seconds},
        :gps => 
          {:longitude => 17.9993, :latitude => 43.1114, :accuracy => 11, 
           :timestamp => Time.now.to_i - 14.seconds}
        }.to_json

    assert_equal Hoccability::EXACT_DATA, last_json_response[:hoccability][:coordinates], "coords"
    assert_equal Hoccability::GOOD_DATA, last_json_response[:hoccability][:wifi], "wifi"
    assert_equal 3, last_json_response[:hoccability][:quality], "maximal overall quality"
  end

end
