require 'test_helper'

class GestureTest < ActiveSupport::TestCase
  
  test "find seeders to own location" do
    Location.delete_all
    Gesture.delete_all
    setup_seeders
    
    #assert_equal 3, Location.find_seeders("")
    
  end
  
  
  def setup_seeders
    create_seeder 52.111, 13.111, 42.1, "throw"
    create_seeder 52.115, 13.115, 42.1, "throw"
    create_seeder 52.122, 13.122, 42.1, "throw"
  end
  
  def create_seeder lat, long, acc, gesture
    loc = Location.create(
      :latitude => 52.111, 
      :longitude => 13.111, 
      :accuracy => 42.1
    )
    
    gesture = loc.gestures.create :name => gesture
    upload  = Upload.create :checksum => "223232323"
    gesture.upload = upload
    upload.save
  end
end
