require 'test_helper'

class GestureTest < ActiveSupport::TestCase

  test "seeding?" do
    
    gesture_1 = Gesture.create :name => "throw"
    assert gesture_1.seeding?
    
    gesture_2 = Gesture.create :name => "catch"
    assert !gesture_2.seeding?
    
  end

end
