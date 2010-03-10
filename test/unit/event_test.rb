require 'test_helper'

class EventTest < ActiveSupport::TestCase

  test "Postgis Point is updated before create" do
    assert_not_nil event = Event.create( :longitude => 52.0, :latitude => 13.0 )
    assert_equal "0101000020E61000000000000000004A400000000000002A40", event.point
  end
  
  test "Postgis Point is updated before update" do
    event = Event.create( :longitude => 52.0, :latitude => 13.0 )
    before = event.point
    event.update_attributes( :longitude => 53.0, :latitude => 14.0 )
    assert before != event.reload.point
  end

end
