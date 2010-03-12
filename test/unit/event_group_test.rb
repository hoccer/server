require 'test_helper'

class EventGroupTest < ActiveSupport::TestCase
  
  test "drop gesture creates deposit event_group" do
    assert_difference "EventGroup.count", +1 do
      Drop.create(
        :longitude    => 52.0, 
        :latitude     => 13.0,
        :starting_at  => Time.now,
        :ending_at    => Time.now
      )
    end
    
    assert_equal 1, Drop.last.event_groups.size
  end
  
  test "pick gesture" do
    pick, drop = nil
    
    assert_difference "EventGroup.count", +1 do
      drop = create_event_with_times( Time.now, (Time.now+1.hours), Drop )
      pick = create_event_with_times( Time.now, (Time.now+1.seconds), Pick )
    end
    
    assert EventGroup.last.events.include?( pick ), "Pick not in EventGroup"
    assert EventGroup.last.events.include?( drop )
  end
  
end
