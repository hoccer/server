require 'test_helper'

class InteractionTest < ActionController::IntegrationTest
  fixtures :all

  test "uploading and receiving a file" do
    
    # Send seeding gesture 
    assert_difference ["Gesture.count", "Upload.count"], +1 do
      post( 
        "/locations/52,1212;13,4242;80/gestures",
        :gesture => {:name => "distribute"}
      )
    end
    
    assert_response :success
    
    assert_equal "distribute", Gesture.last.name
    
    expected =  "{\"uri\": \"http://www.example.com/uploads/#{Upload.last.checksum}\"}"
    assert_equal expected, @response.body
    
    assert_nil Upload.last.attachment_uploaded_at
    
    # Fake uploading a File because else we'd have to fake a multipart form
    
    fake_upload_file
    assert_not_nil Upload.last.attachment_file_name
    
    # Send receiving gesture
    
    get( "/locations/52,1222;13,4262;100/search?gesture=distribute" )
    
    assert_response :success
    
    expected = "{\"uploads\": "\
               "[\"http://www.example.com/uploads/#{Upload.last.checksum}\"]}"
        
    assert_equal expected, @response.body
  end
  
  
  test "downloading a passed upload which was already downloaded" do
    
    prepare_upload
    
    get upload_path(:id => Upload.last.checksum)
    assert_response 200
    
    get upload_path(:id => Upload.last.checksum)
    assert_response 403
    
  end
  
  def prepare_upload
    assert gesture = Gesture.create_located_gesture(
      {:name => "pass"}, "13,44;52,12;42,0"
    )

    attachment = File.new(
      File.join(RAILS_ROOT, "test", "fixtures", "upload_test.jpg")
    )

    gesture.upload.update_attributes :attachment => attachment
    
  end

  def fake_upload_file
    attachment = File.new(
      File.join(RAILS_ROOT, "test", "fixtures", "upload_test.jpg")
    )
    
    gesture  = Gesture.last
    gesture.upload.update_attributes(:attachment => attachment)
    gesture.upload.save
  end
  
end