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
    
    puts Upload.last.inspect
    
  end
end
