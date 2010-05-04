require 'test_helper'

class EventsControllerTest < ActionController::TestCase

  test "create drop event" do
    
    assert_difference "Drop.count", +1 do
      post :create, :event => {
        :type               => "drop",
        :latitude           => 52.0,
        :longitude          => 13.0,
        :location_accuracy  => 100.0,
        :starting_at        => Time.now,
        :ending_at          => 7.seconds.from_now,
        :bssids             => ["ffff", "cccc"]
      }
    end
    
    assert_response       303 #redirect see other
    assert_redirected_to  event_path(:id => Event.last.uuid)
  end
  
  test "create pick event" do
    assert_difference "Pick.count", +1 do
      post :create, :event => {
        :type               => "pick",
        :latitude           => 52.0,
        :longitude          => 13.0,
        :location_accuracy  => 100.0,
        :starting_at        => Time.now,
        :ending_at          => 7.seconds.from_now,
        :bssids             => ["ffff", "cccc"]
      }
    end
    
    assert_response       303 #redirect see other
    assert_redirected_to  event_path(:id => Event.last.uuid)
  end
  
  test "lifetime of drop events" do
    assert_difference "Drop.count", +1 do
      post :create, :event => {
        :type               => "drop",
        :latitude           => 52.0,
        :longitude          => 13.0,
        :location_accuracy  => 100.0,
        :lifetime           => 23.seconds,
        :bssids             => ["ffff", "cccc"],
      }
    end
    
    assert_equal 23, Event.last.ending_at - Event.last.starting_at
  end
  
  test "info response for lonesome drop event" do
    create_event_with_locations( 32.1, 10.5, [{:bssid => "bbbb", :signal => 0.7}], Drop)
    
    get :show, :id => Event.last.uuid
    
    json_response = ActiveSupport::JSON.decode( @response.body )
    
    assert_equal "ready", json_response["state"]
    assert_equal "like state but more verbose", json_response["message"]
    assert json_response["expires"] < 7
    assert_not_nil json_response["upload_uri"]
    assert_equal 0, json_response["peers"]
    assert_equal 200, json_response["status_code"]
  end
  
  test "info response for lonesome pick event" do
    create_event_with_locations( 32.1, 10.5, [{:bssid => "bbbb", :signal => 0.7}], Pick)
    
    get :show, :id => Event.last.uuid
    
    json_response = ActiveSupport::JSON.decode( @response.body )
    
    assert_response 424
    
    assert_equal "no_content", json_response["state"]
    assert_equal "Nothing to pick up from this location", json_response["message"]
    assert_equal 424, json_response["status_code"]
  end
  
  test "info response for pick on exisiting drop" do
    drop = create_event_with_times(Time.now, 7.seconds.from_now, Drop)
    pick = create_event_with_times(Time.now, 7.seconds.from_now, Pick)
    
    get :show, :id => pick.uuid
    
    json_response = ActiveSupport::JSON.decode( @response.body )
    
    assert_response 200
    
    assert_equal "ready", json_response["state"]
    assert_equal "content available for download", json_response["message"]
    assert_equal 0, json_response["uploads"].size
    assert_equal 1, json_response["peers"]
    assert_equal 200, json_response["status_code"]
  end
  
  test "info response for lonesome throw event" do
    throw_event = create_event_with_times(Time.now, 7.seconds.from_now, Throw)
    
    get :show, :id => throw_event.uuid
    
    json_response = ActiveSupport::JSON.decode( @response.body )
    
    assert_response 202
    assert_equal "waiting", json_response["state"]
    assert_equal "waiting for other participants", json_response["message"]
    assert 0 < json_response["expires"], "Event already expired"
    assert_not_nil json_response["upload_uri"]
    assert_equal 0, json_response["peers"]
    assert_equal 202, json_response["status_code"]
  end
  
  test "info response for collision" do
    throw_event = create_event_with_times(Time.now, 7.seconds.from_now, Throw)
    throw_event = create_event_with_times(Time.now, 7.seconds.from_now, Throw)
    
    get :show, :id => throw_event.uuid
    json_response = ActiveSupport::JSON.decode( @response.body )
    
    assert_response 409
    assert_equal "collision", json_response["state"]
  end
  
  test "info response for no_peers" do
    throw_event = create_event_with_times(Time.now, 7.seconds.from_now, Throw)
    expire throw_event.event_group
    
    get :show, :id => throw_event.uuid
    json_response = ActiveSupport::JSON.decode( @response.body )
    
    assert_response 410
    assert_equal "no_peers", json_response["state"]
  end
  
  test "info response for no_seeders" do
    catch_event = create_event_with_times(Time.now, 7.seconds.from_now, Catch)
    expire catch_event.event_group
    
    get :show, :id => catch_event.uuid
    json_response = ActiveSupport::JSON.decode( @response.body )
    
    assert_response 410
    assert_equal "no_seeders", json_response["state"]
  end
  
  test "cancleing a distribute event" do
    catch_event = create_event_with_times(Time.now, 7.seconds.from_now, Catch)
    
    assert_no_difference "Event.count" do
      delete :destroy, :id => catch_event.uuid
    end
    
    assert_equal "canceled", catch_event.reload.state
    assert_equal :canceled, catch_event.info[:state]
  end
  
  test "cancleing a pass event" do
    pass_event = create_event_with_times(Time.now, 7.seconds.from_now, SweepOut)
    
    assert_no_difference "Event.count" do
      delete :destroy, :id => pass_event.uuid
    end
    
    assert_equal "canceled", pass_event.reload.state
    assert_equal :canceled, pass_event.info[:state]
  end
  
  #############################
  #############################
  ##### W A R N I N G ! #######
  ###### Legacy Tests  ########
  #############################
  #############################

  test "creating new seeder peergroup and access points" do
    assert_difference "AccessPointSighting.count", +3 do
      post :create, :peer => {
        :latitude   => 13.44,
        :longitude  => 52.12,
        :accuracy   => 42.0,
        :gesture    => "pass",
        :seeder     => true,
        :bssids     => ["a:a:a:a", "b:b:b:b", "c:c:c:c"],
      }
    end
  end
  
  test "creating new seeder and peer group" do
    assert_difference ["Event.count", "EventGroup.count", "Upload.count"], +1 do
      post :create, :peer => {
        :latitude   => 13.44,
        :longitude  => 52.12,
        :accuracy   => 42.0,
        :gesture    => "pass",
        :seeder     => true
      }
    end
    
    assert_response :success
    json_response = ActiveSupport::JSON.decode( @response.body )
    assert_equal json_response["peer_uri"], event_url(Event.last.uuid)
    assert_equal json_response["upload_uri"], upload_url(Upload.last.uuid)
    
    expire EventGroup.last
    assert_equal 1, (linked_events = Event.last.event_group.events.with_type( "SweepOut" )).size
    assert_not_nil linked_events.first.try(:upload)
  end
  
  test "peers do not receive an upload url upon creation" do
    assert_difference ["Event.count", "EventGroup.count"], +1 do
      post :create, :peer => {
        :latitude   => 13.44,
        :longitude  => 52.12,
        :accuracy   => 42.0,
        :gesture    => "pass",
        :seeder     => false
      }
    end
  
    assert_response :success
    json_response = ActiveSupport::JSON.decode( @response.body )
    assert_equal event_url(Event.first.uuid), json_response["peer_uri"]
    assert_nil json_response["upload_uri"]
  end
  
  test "creating peer without seeder param defaults to seeder=false" do
    assert_difference "SweepIn.count", +1 do
      post :create, :peer => {
        :latitude   => 13.44,
        :longitude  => 52.12,
        :accuracy   => 42.0,
        :gesture    => "pass"
      }
    end
    
    assert_equal Event.last.class, SweepIn
  end
  
  # TODO remove Legacy
  test "querying a throw peer" do
    throw_event = create_event_with_times(7.seconds.ago, 1.seconds.ago, Throw)
    catch_event = create_event_with_times(7.seconds.ago, 1.seconds.ago, Catch)
    
    assert catch_event.expired?, "Event Group is not expired"
    get :show, :id => catch_event.uuid
    
    json_response = ActiveSupport::JSON.decode( @response.body )
    assert_equal 200, catch_event.info[:status_code]
  end
  
  test "legacy clients have proper uploads in info hash" do
    throw_event = create_event_with_times(7.seconds.ago, 1.seconds.ago, Throw)
    catch_event = create_event_with_times(7.seconds.ago, 1.seconds.ago, Catch)
    
    assert catch_event.expired?, "Event Group is not expired"
    catch_event.update_attribute(:api_version, 1)
    
    get :show, :id => catch_event.uuid
    
    json_response = ActiveSupport::JSON.decode( @response.body )
    
    assert_equal throw_event.upload.uuid, catch_event.info[:resources][0]
    assert_equal 200, catch_event.info[:status_code]
  end
  
  test "querying a pass peer" do
    throw_event = create_event_with_times(7.seconds.ago, 1.seconds.ago, SweepOut)
    catch_event = create_event_with_times(7.seconds.ago, 1.seconds.ago, SweepIn)
    
    assert catch_event.expired?, "Event Group is not expired"
    get :show, :id => catch_event.uuid
    
    json_response = ActiveSupport::JSON.decode( @response.body )
    assert_equal 200, catch_event.info[:status_code]
  end
  
  test "bssid normalization" do
    post :create, :peer => {
      :latitude   => 13.44,
      :longitude  => 52.12,
      :accuracy   => 42.0,
      :gesture    => "pass",
      :seeder     => true,
      :bssids     => ["fa:a:2a:a", "b:9:b0:b", "1:22:f:f0", "ff:ff:ff:ff"]
    }
    
    expected  = ["fa:0a:2a:0a", "0b:09:b0:0b", "01:22:0f:f0", "ff:ff:ff:ff"]
    event     = Event.last
    
    assert_equal expected.sort, event.access_point_sightings.map(&:bssid).sort
  end
  
  
end
