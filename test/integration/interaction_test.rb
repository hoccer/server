require 'test_helper'

class InteractionTest < ActionController::IntegrationTest
  fixtures :all

  test "uploading and receiving a file" do
    
    # Send seeding gesture 
    
    assert_difference ["Location.count", "Gesture.count", "Upload.count"], +1 do
      post( 
        "/locations/52,1212;13,4242;80/gestures",
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
    
    get( "/locations/52,1222;13,4262;100/search?gesture=distribute" )
    
    assert_response :success
    
    expected = "{\"uploads\": "\
               "[\"http://www.example.com/uploads/#{Upload.last.checksum}\"]}"
        
    assert_equal expected, @response.body
  end
  
  
  test "downloading a passed upload which was already downloaded" do
    
    prepare_upload
    
    get upload_path(:id => "23232323")
    assert_response 200
    
    get upload_path(:id => "23232323")
    assert_response 403
    
  end
  
  def prepare_upload
    location = Location.create(
      :latitude => 13.44, :longitude => 52.12, :accuracy => 42.0
    )
    
    gesture = location.gestures.create :name => "pass"

    attachment = File.new(
      File.join(RAILS_ROOT, "test", "fixtures", "upload_test.jpg")
    )

    upload = Upload.create(
      :checksum => "23232323", :attachment => attachment
    )
    
    gesture.upload = upload
    upload.save
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