require 'test_helper'

class LegacyDistributeTest < ActiveSupport::TestCase
  
  test "first (Legacy)Throw on location creates new peer group" do
    assert_difference "EventGroup.count", +1 do
      create_event_with_locations(44.1, 44.5, [], LegacyThrow)
    end
    assert_not_nil Event.last.event_group
  end
  
  test "following peers join exisiting peer group instead of creating one" do
    event = create_event_with_locations(44.1, 44.5, [], LegacyThrow)
    assert_no_difference "EventGroup.count" do
      create_event_with_locations(44.1, 44.5, [], LegacyCatch)
    end
    
    assert_not_nil event.event_group
  end
  
  test "status and status response is a hash" do
    event_a = create_event_with_locations(44.1, 44.5, [], LegacyThrow)
    event_b = create_event_with_locations(44.1, 44.5, [], LegacyCatch)
    
    assert event_a.info
    assert event_a.info.class == Hash
  end
  
  test "current_state :collision" do
    event_a = create_event_with_locations(44.1, 44.5, [], LegacyPass)
    event_b = create_event_with_locations(44.1, 44.5, [], LegacyPass)
    
    assert_equal :collision, event_a.reload.info[:state]
  end
  
  test "current_state :waiting" do
    event_a = create_event_with_locations(44.1, 44.5, [], LegacyPass)
    event_b = create_event_with_locations(44.1, 44.5, [], LegacyReceive)
    
    assert_equal :waiting, event_b.reload.info[:state]
  end
  
  test "current_state :ready" do
    event_a = create_event_with_locations(44.1, 44.5, [], LegacyPass)
    event_b = create_event_with_locations(44.1, 44.5, [], LegacyReceive)
    
    expire event_a.event_group
    
    assert_equal :ready, event_a.info[:state]
    assert_equal :ready, event_b.info[:state]
  end
  
end