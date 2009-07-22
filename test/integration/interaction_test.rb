require 'test_helper'

class InteractionTest < ActionController::IntegrationTest
  fixtures :all

  test "uploading and receiving a file" do
    
    # Send seeding gesture 
    
    assert_difference ["Location.count", "Gesture.count", "Upload.count"], +1 do
      post( 
        "/locations/52,1212;13,4242;42,5/gestures",
        :gesture => {:name => "distribute"}
      )
    end
    
    assert_response :success
    
    assert_equal "distribute", Gesture.last.name
    assert_equal Gesture.last.location, Location.last
    
    expected =  "{\"uri\": \"http://www.example.com/uploads/#{Upload.last.checksum}\"}"
    assert_equal expected, @response.body
    
    assert_nil Upload.last.attachment_uploaded_at
    
    # Fake uploading a File because else we'd have to fake a multipart form
    
    fake_upload_file
    assert_not_nil Upload.last.attachment_file_name
    
    # Send receiving gesture
    
    get( "/locations/52,1222;13,4262;42,5/search?gesture=distribute" )
    
    assert_response :success
    
    expected = "{\"uploads\": "\
               "[\"http://www.example.com/uploads/#{Upload.last.checksum}\"]}"
        
    assert_equal expected, @response.body
  end
  
  
  def fake_upload_file
    attachment = File.new(
      File.join(RAILS_ROOT, "test", "fixtures", "upload_test.jpg")
    )
    
    gesture  = Location.last.gestures.last
    gesture.upload.update_attributes(:attachment => attachment)
    gesture.upload.save
  end
  
end