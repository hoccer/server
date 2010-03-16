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
  
  test "status for lonesome drop event" do
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
  
end
