require 'test_helper'

class UploadsControllerTest < ActionController::TestCase
  
  test "updating an upload" do
    Upload.create :checksum => "23"
    
    tmpfile = File.new(
      File.join(RAILS_ROOT, "test", "fixtures", "upload_test.jpg")
    )
    
    put( 
      :update,
      :upload => {:attachment => tmpfile},
      :id => Upload.last.checksum
    )
  end
  
  test "fetching an upload without an attachment" do
    Upload.create :checksum => "2323232323"
    get :show, :id => "2323232323"
    assert_response 204
  end
  
  test "fetching an upload with an attachment" do
    location = Location.create(
      :latitude => 13.44, :longitude => 52.12, :accuracy => 42.0
    )
    
    gesture = location.gestures.create :name => "throw"

    upload = Upload.create(
      :checksum => "23232323"
    )
    
    gesture.upload = upload
    upload.save

    attachment = File.new(
      File.join(RAILS_ROOT, "test", "fixtures", "upload_test.jpg")
    )

    put(
      :update,
      :upload => {:attachment => attachment},
      :id => Upload.last.checksum
    )
    
    get :show, :id => "23232323"
    assert_response 200
  end
  
  
  
end
