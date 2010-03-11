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
  
  test "within_timeframe with two equal events" do
    2.times { create_event_with_times( Time.now, (Time.now + 7.seconds) ) }
    
    event = Event.last
    
    assert_equal 1, event.within_timeframe.size
    assert event != event.within_timeframe.first
  end
  
  test "within_timeframe with overlapping events - first is first" do
    create_event_with_times( Time.now, (Time.now + 7.seconds) )
    create_event_with_times( (Time.now + 4.seconds), (Time.now + 11.seconds) )
    
    event = Event.last
    
    assert_equal 1, event.within_timeframe.size
    assert event != event.within_timeframe.first
  end
  
  test "within_timeframe with overlapping events - first is second" do
    create_event_with_times( (Time.now + 4.seconds), (Time.now + 11.seconds) )
    create_event_with_times( Time.now, (Time.now + 7.seconds) )
    
    event = Event.last
    
    assert_equal 1, event.within_timeframe.size
    assert event != event.within_timeframe.first
  end
  
  test "within_timeframe with non overlapping events - first is first" do
    create_event_with_times( Time.now, (Time.now + 7.seconds) )
    create_event_with_times( (Time.now + 23.seconds), (Time.now + 30.seconds) )
    
    event = Event.last
    
    assert_equal 0, event.within_timeframe.size
  end
  
  
  def create_event_with_times starting_at, ending_at
    Event.create( 
      :longitude    => 52.0, 
      :latitude     => 13.0,
      :starting_at  => starting_at,
      :ending_at    => ending_at
    )
  end
end
