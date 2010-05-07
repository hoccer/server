require 'test_helper'

class DropPickTest < ActionController::IntegrationTest
  fixtures :all
  
  test "lonesome drop event" do
    post events_path, :event => {
      :type               => "drop",
      :latitude           => 52.0,
      :longitude          => 13.0,
      :location_accuracy  => 100.0,
      :lifetime           => 30.minutes,
      :bssids             => ["ffff", "cccc"]
    }
    
    follow_redirect!
    
    assert_response 202
    
    json_response = ActiveSupport::JSON.decode(@response.body)
    
    assert_equal "waiting", json_response["state"]
    assert (29.minutes..30.minutes).include? json_response["expires"]
  end
  
  test "lonesome pick event" do
    post events_path, :event => {
      :type               => "pick",
      :latitude           => 52.0,
      :longitude          => 13.0,
      :location_accuracy  => 100.0,
      :bssids             => ["ffff", "cccc"]
    }
    
    assert_response 303
    follow_redirect!
    
    assert_response 424
    
    json_response = ActiveSupport::JSON.decode(@response.body)
    
    assert_equal json_response.keys.sort, %w(event_uri message state status_code)
  end
  
  test "pick event with drop event nearby" do
    post events_path, :event => {
      :type               => "drop",
      :latitude           => 52.0,
      :longitude          => 13.0,
      :location_accuracy  => 100.0,
      :lifetime           => 30.minutes,
      :bssids             => ["ffff", "cccc"]
    }
    
    follow_redirect!
    
    # Upload file to upload_uri
    
    test_upload = fixture_file_upload("test_upload.jpeg", "image/jpeg")
    
    put(
      upload_path(:id => Upload.last.uuid),
      :upload => { :attachment => test_upload },
      :html   => { :multipart => true }
    )
    
    post events_path, :event => {
      :type               => "pick",
      :latitude           => 52.0,
      :longitude          => 13.0,
      :location_accuracy  => 100.0,
      :bssids             => ["ffff", "cccc"]
    }
    
    follow_redirect!
    
    json_response = ActiveSupport::JSON.decode(@response.body)
  end
  
  test "create drop event and verify response" do
    
    # 1. Create Drop Event
    
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
    
    drop_event    = Drop.last
    json_response = ActiveSupport::JSON.decode(@response.body)
    
    assert_equal upload_url(drop_event.upload.uuid), json_response["upload_uri"]
    
    # 2. Upload file to upload_uri
    
    test_upload = fixture_file_upload("test_upload.jpeg", "image/jpeg")
    
    put(
      upload_path(:id => Upload.last.uuid),
      :upload => { :attachment => test_upload },
      :html   => { :multipart => true }
    )
    
    drop_event.reload
    assert_equal "test_upload.jpeg", drop_event.upload.attachment.original_filename
    
    # 3. Pick up the dropped file
    
    post events_path, :event => {
      :type               => "pick",
      :latitude           => 52.0,
      :longitude          => 13.0,
      :location_accuracy  => 100.0,
      :starting_at        => Time.now,
      :ending_at          => 7.seconds.from_now,
      :bssids             => ["ffff", "cccc"]
    }
    
    assert_response 303
    follow_redirect!
    
    pick_event    = Pick.last
  end
  
end
