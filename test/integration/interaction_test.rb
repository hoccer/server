require 'test_helper'

class InteractionTest < ActionController::IntegrationTest
  fixtures :all

  test "uploading and receiving a file" do
    
    # Upload 
    
    assert_difference ["Location.count", "Gesture.count"], +1 do
      post( 
        "/locations/52,1212;13,4242;42,5/gestures",
        :gesture => {:name => "throw"}
      )
    end
    
    assert_response :success
    assert_equal "throw", Gesture.last.name
    assert_equal Gesture.last.location, Location.last
    
 
    
    expected =  '{"uri": "http://www.example.com/locations/52,1212;13,4242;42,5/gestures/' + Gesture.last.id.to_s +  '"}'
    assert_equal expected, @response.body
    
    # Fake uploading a File because else we'd have to fake a multipart form
    
    attachment = File.new(
      File.join(RAILS_ROOT, "test", "fixtures", "upload_test.jpg")
    )
    
    upload    = Upload.create :attachment => attachment
    gesture  = Location.last.gestures.last
    gesture.uploads << upload
    gesture.save
    assert_not_nil Upload.last.attachment_file_name
    
    assert_response :success
    
    # Send receiving gesture
    
    assert_difference ["Location.count", "Gesture.count"], +1 do
    
    get( "/locations/52,1222;13,4262;42,5?gestures=catch" )
    end
    assert_response :success 
    expected =  '{"uri": "http://www.example.com/locations/52,1212;13,4242;42,5/gestures/' + Gesture.last.id.to_s +  '"}'
    assert_equal expected, @response.body
    
    # Poll for receipt
    
    get "/locations/52,1212;13,4242;42,5"
    assert_response :success
    upload_path = upload.attachment.url.sub(/\?\d+/, "")
    expected    = "{\"files\": [\"http://www.example.com#{upload_path}\"]}"
    assert_equal expected, @response.body
  end
  

end
