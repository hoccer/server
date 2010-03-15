require 'test_helper'

class DropPickTest < ActionController::IntegrationTest
  fixtures :all
  
  test "create drop event and verify response" do
    
    post events_path, :event => {
      :type               => "drop",
      :latitude           => 52.0,
      :longitude          => 13.0,
      :location_accuracy  => 100.0,
      :starting_at        => Time.now,
      :ending_at          => 7.seconds.from_now,
      :bssids             => ["ffff", "cccc"]
    }
    
    assert_response 303
    follow_redirect!
    
    event         = Event.last
    json_response = ActiveSupport::JSON.decode(@response.body)
    
    assert_equal upload_url(event.upload.uuid), json_response["upload_uri"]
    
  end
  
end
