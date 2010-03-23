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
    assert_equal 1, json_response["uploads"].size
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
    assert_equal upload_url(:id => Upload.first.uuid), json_response["uploads"][0]["uri"]
  end
  
  test "querying a pass peer" do
    throw_event = create_event_with_times(7.seconds.ago, 1.seconds.ago, SweepOut)
    catch_event = create_event_with_times(7.seconds.ago, 1.seconds.ago, SweepIn)
    
    assert catch_event.expired?, "Event Group is not expired"
    get :show, :id => catch_event.uuid
    
    json_response = ActiveSupport::JSON.decode( @response.body )
    assert_equal upload_url(:id => Upload.first.uuid), json_response["uploads"][0]["uri"]
  end
  
  
end