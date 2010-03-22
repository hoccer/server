require 'test_helper'

class EventTest < ActiveSupport::TestCase
  
  test "should not create access points if peer is invalid" do
    assert_no_difference "AccessPointSighting.count" do
      Event.create(
        :latitude   => 44.1,
        :location_accuracy   => 23.0,
        :access_point_sightings_attributes => [
          { :bssid => "ffff" },
          { :bssid => "eeee" },
          { :bssid => "aaaa" }
        ]
      )
    end
  end
  
  test "should create 3 accesspoints for valid peer" do
    assert_difference "AccessPointSighting.count", +3 do
      Event.create(
        :latitude   => 44.1,
        :longitude  => 23.0,
        :location_accuracy   => 23.0,
        :access_point_sightings_attributes => [
          { :bssid => "ffff" },
          { :bssid => "eeee" },
          { :bssid => "aaaa" }
        ]
      )
    end
  end
  
  test "uuid added to new events" do
    event = create_event_with_locations( 52.0, 13.0 )
    assert_not_nil event.uuid
    assert_equal 32, event.uuid.size
  end

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
  
  test "access_point_sightings" do
    AccessPointSighting.delete_all
    assert_equal [], create_event_with_locations( 52.0, 13.0 ).access_point_sightings
  end
  
  test "event accepts nested access_point_sightings attributes" do
    assert_difference "AccessPointSighting.count", +1 do
      create_event_with_locations( 52.0, 13.0, [{:bssid => "ffff", :signal => 1.0}])
    end
    assert_equal "ffff", AccessPointSighting.last.bssid
    assert (0.9..1.1).include? AccessPointSighting.last.signal
  end
  
  test "find nearby events with matching bssids" do
    create_event_with_locations( 32.1, 10.5, [{:bssid => "bbbb", :signal => 0.7}])
    create_event_with_locations( 10.0, 51.5, [{:bssid => "bbbb", :signal => 0.7}])
    
    assert_equal 1, Event.last.nearby_events.size
  end
  
  test "find nearby events with no matching bssids" do
    create_event_with_locations( 32.1, 10.5, [{:bssid => "bbbb", :signal => 0.7}])
    create_event_with_locations( 10.0, 51.5, [{:bssid => "cccc", :signal => 0.7}])
    
    assert_equal 0, Event.last.nearby_events.size
  end
  
  test "find nearby events with multiple matching bssids" do
    create_event_with_locations(
      32.1,
      10.5, 
      [{:bssid => "oooo", :signal => 0.7},
       {:bssid => "cccc", :signal => 0.7},
       {:bssid => "hhhh", :signal => 0.7}]
    )
    create_event_with_locations(
      10.0,
      51.5,
      [{:bssid => "bbbb", :signal => 0.7},
       {:bssid => "cccc", :signal => 0.7},
       {:bssid => "xxxx", :signal => 0.7}]
    )
    
    assert_equal 1, Event.last.nearby_events.size
  end
  
  test "find nearby events with no multiple matching bssids" do
    create_event_with_locations(
      32.1,
      10.5, 
      [{:bssid => "oooo", :signal => 0.7},
       {:bssid => "cccc", :signal => 0.7},
       {:bssid => "hhhh", :signal => 0.7}]
    )
    create_event_with_locations(
      10.0,
      51.5,
      [{:bssid => "bbbb", :signal => 0.7},
       {:bssid => "iiii", :signal => 0.7},
       {:bssid => "xxxx", :signal => 0.7}]
    )
    assert_equal 0, Event.last.nearby_events.size
  end
  
  test "no peers found if too far away and different bssids" do
    event_a = create_event_with_locations(
      32.1,
      10.5, 
      [{:bssid => "aaa1", :signal => 0.7},
       {:bssid => "aaa2", :signal => 0.7},
       {:bssid => "aaa3", :signal => 0.7}]
    )
    
    event_b = create_event_with_locations(
      3.1,
      1.5, 
      [{:bssid => "bbb1", :signal => 0.7},
       {:bssid => "bbb2", :signal => 0.7},
       {:bssid => "bbb3", :signal => 0.7}]
    )
    
    event_c = create_event_with_locations(
      44.1,
      44.5, 
      [{:bssid => "ccc1", :signal => 0.7},
       {:bssid => "ccc2", :signal => 0.7},
       {:bssid => "ccc3", :signal => 0.7}]
    )
    
    assert_equal 0, event_a.nearby_events.count
    assert_equal 0, event_b.nearby_events.count
    assert_equal 0, event_c.nearby_events.count
  end
  
  test "multiple peers found by location even if bssids differ" do
    event_a = create_event_with_locations(
      32.1,
      10.5, 
      [{:bssid => "aaa1", :signal => 0.7},
       {:bssid => "aaa2", :signal => 0.7},
       {:bssid => "aaa3", :signal => 0.7}]
    )
    
    event_b = create_event_with_locations(
      32.1,
      10.5, 
      [{:bssid => "bbb1", :signal => 0.7},
       {:bssid => "bbb2", :signal => 0.7},
       {:bssid => "bbb3", :signal => 0.7}]
    )
    
    event_c = create_event_with_locations(
      32.1,
      10.5, 
      [{:bssid => "ccc1", :signal => 0.7},
       {:bssid => "ccc2", :signal => 0.7},
       {:bssid => "ccc3", :signal => 0.7}]
    )
    assert_equal 2, event_a.nearby_events.count
  end
  
  test "find peers in range or bssids" do
    Event.delete_all
    
    event_a = create_event_with_locations(
      32.1,
      10.5, 
      [{:bssid => "aaa1", :signal => 0.7},
       {:bssid => "aaa2", :signal => 0.7},
       {:bssid => "aaa3", :signal => 0.7}]
    )
    
    event_b = create_event_with_locations(
      32.1,
      10.5, 
      [{:bssid => "bbb1", :signal => 0.7},
       {:bssid => "bbb2", :signal => 0.7},
       {:bssid => "bbb3", :signal => 0.7}]
    )
    
    event_c = create_event_with_locations(
      44.1,
      44.5, 
      [{:bssid => "ccc1", :signal => 0.7},
       {:bssid => "aaa2", :signal => 0.7},
       {:bssid => "ccc3", :signal => 0.7}]
    )  
    
    assert_equal 2, event_a.nearby_events.count
  end
  
  test "another falsification" do
    event_a = create_event_with_locations(
      52.501077,
      13.345116,
      [{:bssid => "aaa1", :signal => 0.7},
       {:bssid => "aaa2", :signal => 0.7},
       {:bssid => "aaa3", :signal => 0.7}]
    )
    
    event_b = create_event_with_locations(
      52.500927,
      13.345738,
      [{:bssid => "bbb1", :signal => 0.7},
       {:bssid => "bbb2", :signal => 0.7},
       {:bssid => "bbb3", :signal => 0.7}]
    )
    
    event_c = create_event_with_locations(
      20.501616,
      20.345785,
      [{:bssid => "aaa1", :signal => 0.7},
       {:bssid => "ccc2", :signal => 0.7},
       {:bssid => "ccc3", :signal => 0.7}]
    )
    
    event_d = create_event_with_locations(
      20.501616,
      20.345785,
      [{:bssid => "ccc1", :signal => 0.7},
       {:bssid => "ccc2", :signal => 0.7},
       {:bssid => "ccc3", :signal => 0.7}]
    )
    
    assert_equal 2, event_a.nearby_events.count
  end
  
  test "first event in distribute sets lifetime" do
    catch_event = create_event_with_locations(44.1, 44.5, [], Catch)
    throw_event = create_event_with_locations(44.1, 44.5, [], Throw)
    
    assert_equal catch_event.ending_at, catch_event.latest_in_group
  end
  
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
  
  test "creating a drop event auto creates an upload as well" do
    assert_difference "Upload.count", +1 do
      create_event_with_locations( 52.0, 13.0, [], Drop )
    end
  end
  
end
