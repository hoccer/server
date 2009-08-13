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
    assert gesture = Gesture.create_located_gesture(
      {:name => "throw"}, "13,44;52,12;42,0"
    )
    
    assert gesture.upload
        
    get :show, :id => gesture.upload.checksum
    assert_response 204
  end
  
  test "fetching an upload with an attachment" do
    assert gesture = Gesture.create_located_gesture(
      {:name => "throw"}, "13,44;52,12;42,0"
    )

    attachment = File.new(
      File.join(RAILS_ROOT, "test", "fixtures", "upload_test.jpg")
    )

    put(
      :update,
      :upload => {:attachment => attachment},
      :id => Upload.last.checksum
    )
    
    get :show, :id => gesture.upload.checksum
    assert_response 200
  end
  
  
end
