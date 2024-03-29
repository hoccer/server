$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), ".."))
require 'helper'

class TestHoccer < Test::Unit::TestCase
  include Sinatra::Async::Test::Methods

  def setup
    Client.delete_all
    #@client = Client.create
  end

  test "accessing the db" do
    EM.run do
      db ||= EM::Mongo::Connection.new.db('hoccer_v3')
      collection = db.collection('clients')
      EM.next_tick do
      collection.insert :uuid => 1
      end
      EM.stop
    end
  end

  #test "registering a new client" do
  #  EM.run do
  #  post "clients", {:device => "ios4"}.to_json
  #  assert_equal 303, last_response.status
  #  assert last_response.headers["Location"] =~ /\/clients\/[a-z0-9]/
  #  puts ">>>>>>>>>>>>>>>!!!!!!!!!!!!!!!!>>>>>>>>>>>>>>>>"
  #  Hoccer::Client.collection.find() do |res|
  #    puts res.inspect
  #  end
  #  EM.stop
  #  end
  #end

  #test "client requests self_reference" do
  #  get "/clients/#{@client.uuid}"
  #  expected = "{\"uri\":\"/clients/#{@client.uuid}\"}"
  #  assert_equal expected, last_response.body
  #end

  #test "client requests self reference with malicious_uuid" do
  #  get "/clients/c7dde7f09bef012d8e37001f5bf1b5ba"
  #  assert_equal 410, last_response.status
  #end

  #test "client updates environment without sending a body" do
  #  put "/clients/#{@client.uuid}/environment"
  #  assert_async
  #  async_continue
  #  assert_equal 410, last_response.status
  #end

  #test "client updates environment with invalid json" do
  #  put "/clients/#{@client.uuid}/environment", "{sahasdhasd7"
  #  assert_async
  #  async_continue
  #  assert_equal 410, last_response.status
  #end

  #test "client updates its environment without being grouped" do
  #  env = {:foo => "bar"}.to_json
  #  put "/clients/#{@client.uuid}/environment", env
  #  assert_async
  #  em_async_continue
  #  assert_equal 200, last_response.status
  #  assert_not_nil  @client.environment
  #  assert_nil      @client.group_id
  #end

  #test "clients updates its environment with being grouped" do
  #  @client_2 = Client.create(
  #    :environment => {
  #      "gps" => { "longitude" => 13.1, "latitude" => 14.1 }
  #    }
  #  )

  #  env = {"gps" => { "longitude" => 13.1, "latitude" => 14.1 }}.to_json
  #  put "/clients/#{@client.uuid}/environment", env
  #  assert_async
  #  em_async_continue
  #  assert_equal 200, last_response.status

  #  assert_not_nil @client.group_id
  #  assert_equal @client.group_id, @client_2.group_id
  #  assert_equal 1, @client.neighbors.size
  #end

  #test "posting a share action" do
  #  @client.environment = {"gps" => { "longitude" => 13.1, "latitude" => 14.1 }}
  #  @client_2 = Client.create(
  #    :environment => {
  #      "gps" => { "longitude" => 13.1, "latitude" => 14.1 }
  #    }
  #  )
  #  json = [{:inline => "hallo welt"}].to_json

  #  post "/clients/#{@client.uuid}/action/pass", json
  #  assert_equal 303, last_response.status
  #  exp = "/clients/#{@client.uuid}/action/pass/#{@client.actions[:pass][:uuid]}"
  #  assert_equal exp, last_response.headers["Location"]
  #  assert_equal true, @client.actions.keys.include?( :pass )
  #end

  #test "trying to receive with an action" do
  #  @client.environment = {"gps" => { "longitude" => 13.1, "latitude" => 14.2 }}
  #  @client_2 = Client.create(
  #    :environment => {
  #      "gps" => { "longitude" => 13.1, "latitude" => 14.2}
  #    }
  #  )
  #  @client.rebuild_groups

  #  assert_equal @client.group_id, @client_2.group_id
  #  @client.actions[:pass] = { :payload =>[{:inline => "foo"}] }
  #  @client.mode = :sender
  #  @client.request = FakeRequest.new

  #  get "/clients/#{@client_2.uuid}/action/pass"
  #  assert_async
  #  em_async_continue

  #  assert_equal 200, last_response.status
  #end

  #test "deleting the client environment" do
  #  @client.environment = {"gps" => { "longitude" => 13.2, "latitude" => 14.2 }}

  #  delete "/clients/#{@client.uuid}/environment"
  #  assert_equal 200, last_response.status
  #  assert_nil @client.group_id
  #  assert_equal Hash.new, @client.environment
  #end

  #test "sharing actual data" do
  #  # Prepare sending client
  #  @client.environment = {"gps" => { "longitude" => 13.2, "latitude" => 14.2 }}
  #  @client.actions[:pass] = { :payload => { :inline => "hello world !!1" } }
  #  @client.mode = :sender

  #  # Prepare receiving client
  #  @client_2 = Client.create(
  #    :environment => {
  #      "gps" => { "longitude" => 13.2, "latitude" => 14.2 }
  #    }
  #  )

  #  # Group them together
  #  @client.rebuild_groups
  #  assert_not_nil @client.group_id
  #  assert_equal @client.group_id, @client_2.group_id
  #  get "/clients/#{@client_2.uuid}/action/pass"
  #  assert_async
  #  em_async_continue
  #  expected = '[{"inline":"hello world !!1"}]'
  #  assert_equal expected, last_response.body
  #  assert_equal 200, last_response.status
  #end
end
