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
  
  test "nearby_events with two equal events" do
    2.times { create_event_with_times( Time.now, (Time.now + 7.seconds) ) }
    
    event = Event.last
    
    assert_equal 1, event.nearby_events.size
    assert event != event.nearby_events.first
  end
  
  test "nearby_events with overlapping events - first is first" do
    create_event_with_times( Time.now, (Time.now + 7.seconds) )
    create_event_with_times( (Time.now + 4.seconds), (Time.now + 11.seconds) )
    
    event = Event.last
    
    assert_equal 1, event.nearby_events.size
    assert event != event.nearby_events.first
  end
  
  test "nearby_events with overlapping events - first is second" do
    create_event_with_times( (Time.now + 4.seconds), (Time.now + 11.seconds) )
    create_event_with_times( Time.now, (Time.now + 7.seconds) )
    
    event = Event.last
    
    assert_equal 1, event.nearby_events.size
    assert event != event.nearby_events.first
  end
  
  test "nearby_events with non overlapping events - first is first" do
    create_event_with_times( Time.now, (Time.now + 7.seconds) )
    create_event_with_times( (Time.now + 23.seconds), (Time.now + 30.seconds) )
    
    event = Event.last
    
    assert_equal 0, event.nearby_events.size
  end
  
  test "nearby_events with non overlapping events - first is second" do
    create_event_with_times( (Time.now + 23.seconds), (Time.now + 30.seconds) )
    create_event_with_times( Time.now, (Time.now + 7.seconds) )
    
    event = Event.last
    
    assert_equal 0, event.nearby_events.size
  end
  
  test "overlapping time and different locations but within radius" do
    create_event_with_locations( 52.0, 13.0 )
    create_event_with_locations( 52.00000001, 13.00000001 )
    
    assert_equal 1, Event.last.nearby_events.size
  end
  
  test "overlapping time but out of radius" do
    create_event_with_locations( 52.0, 13.0 )
    create_event_with_locations( 53.0, 14.0 )
    
    assert_equal 0, Event.last.nearby_events.size
  end
  
  
  def create_event_with_times starting_at, ending_at
    Event.create( 
      :longitude    => 52.0, 
      :latitude     => 13.0,
      :starting_at  => starting_at,
      :ending_at    => ending_at
    )
  end
  
  def create_event_with_locations latitude, longitude
    Event.create( 
      :longitude    => latitude, 
      :latitude     => longitude,
      :starting_at  => Time.now,
      :ending_at    => Time.now+7.seconds
    )
  end
end
