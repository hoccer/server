require 'test_helper'

class InteractionTest < ActionController::IntegrationTest
  fixtures :all

  test "uploading and receiving a file" do
    
    # Upload 
    
    assert_difference ["Location.count", "Gesture.count"], +1 do
      post( 
        "/locations/52,1212;13,4242;42,5/gestures",
        :gesture => {:name => "throw"},
        :filename => "upload_test.jpg"
      )
    end

    assert_response :success
    
    assert_equal "throw", Gesture.last.name
    assert_equal Gesture.last.location, Location.last
    
    expected =  '{"uri": "http://www.example.com/locations/52,1212;13,4242;42,5/gestures/' + Gesture.last.id.to_s +  '"}'
    assert_equal expected, @response.body
    
    # Fake uploading a File because else we'd have to fake a multipart form
    
    fake_upload_file
    assert_not_nil Upload.last.attachment_file_name
    
    # Send receiving gesture
    
    
    get( "/locations/52,1222;13,4262;42,5/search?gesture=catch" )
    
    assert_response :success
    
    expected = "{\"http://www.example.com/locations/52,1212;13,4242;42,5/" \
               "gestures/#{Gesture.last.id}\": {\"uploads\": "\
               "[\"http://www.example.com#{Upload.last.attachment.url}\"]}}"
    
    assert_equal expected, @response.body
  end
  
  
  def fake_upload_file
    attachment = File.new(
      File.join(RAILS_ROOT, "test", "fixtures", "upload_test.jpg")
    )
    
    upload    = Upload.create :attachment => attachment
    gesture  = Location.last.gestures.last
    gesture.uploads << upload
    gesture.save
  end
  

end
