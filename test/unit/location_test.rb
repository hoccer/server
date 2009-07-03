require 'test_helper'

class LocationTest < ActiveSupport::TestCase
  
  
  test "create_from url parameters" do
    
    assert_difference "Location.count", +1 do
      Location.create_from "52,1212;13,4242;42,5"
    end
    
    assert_equal 52.1212,   Location.last.latitude
    assert_equal 13.4242,   Location.last.longitude
    assert_equal 42.5,      Location.last.accuracy
    
  end
  
  test "find by url location" do
    assert_not_nil Location.find_by_coordinates("52,5211;13,1199;23,42")
  end
  
  test "coordinate serialization" do
    
    expected = "52,5211;13,1199;23,42"
    
    assert_equal expected, Location.first.serialized_coordinates
    
  end
end
