require 'test_helper'

class UploadsControllerTest < ActionController::TestCase

  test "uploading a file" do
    @upload = File.new(
      File.join(RAILS_ROOT, "test", "fixtures", "upload_test.jpg")
    )
    
    post( 
      :create,
      :upload => {:attachment => @upload},
      :location_id => "52,5211;13,1199;23,42"
    )
    
  end
end
