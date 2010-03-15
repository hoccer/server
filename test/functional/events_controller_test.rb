require 'test_helper'

class EventsControllerTest < ActionController::TestCase

  test "create drop event" do
    
    assert_difference ["Drop.count", "Deposit.count"], +1 do
      post :create, :event => {
        :type               => "drop",
        :latitude           => 52.0,
        :longitude          => 13.0,
        :location_accuracy  => 100.0,
        :starting_at        => Time.now,
        :ending_at          => 7.seconds.from_now,
        :access_point_sightings_attributes => [:bssid => "ffff", :bssid => "cccc"]
      }
    end
    
    assert_response       303 #redirect see other
    assert_redirected_to  event_path(Event.last)
  end
  
  test "create pick event" do
    assert_difference ["Pick.count"], +1 do
      post :create, :event => {
        :type               => "pick",
        :latitude           => 52.0,
        :longitude          => 13.0,
        :location_accuracy  => 100.0,
        :starting_at        => Time.now,
        :ending_at          => 7.seconds.from_now,
        :access_point_sightings_attributes => [:bssid => "ffff", :bssid => "cccc"]
      }
    end
    
    assert_response       303 #redirect see other
    assert_redirected_to  event_path(Event.last)
  end
  
  
end
