require 'test_helper'

class EventTest < ActiveSupport::TestCase

  test "pairing with bssids and no lon/lat" do
    event_a = create_event_with_locations(nil, nil, [{:bssid => "ffff"}], Throw)
    event_b = create_event_with_locations(20.1, 2.0, [{:bssid => "ffff"}], Catch)
    assert_equal 1, event_a.nearby_events.size
    assert_equal event_a.event_group, event_b.event_group
  end

  test "pairing by location only sets pairing mode to 1" do
    event_a = create_event_with_locations(20.501616, 20.345785, [])
    event_b = create_event_with_locations(20.501616, 20.345785, [])

    event_a.nearby_events
    event_b.nearby_events

    assert_equal 1, event_a.pairing_mode
    assert_equal 1, event_b.pairing_mode
  end

  test "pairing by bssid only sets pairing mode to 2" do
    event_a = create_event_with_locations(20.0, 1.0, [{:bssid => "ffff"}])
    event_b = create_event_with_locations(20.1, 2.0, [{:bssid => "ffff"}])

    event_a.nearby_events
    event_b.nearby_events

    assert_equal 2, event_a.pairing_mode
    assert_equal 2, event_b.pairing_mode
  end

  test "pairing by bssid and location sets pairing mode to 3" do
    event_a = create_event_with_locations(20.0, 1.0, [{:bssid => "ffff"}])
    event_b = create_event_with_locations(20.0, 1.0, [{:bssid => "ffff"}])

    event_a.nearby_events
    event_b.nearby_events

    assert_equal 3, event_a.pairing_mode
    assert_equal 3, event_b.pairing_mode
  end

  test "should create access points if peer has no lat/long" do
    assert_difference "AccessPointSighting.count", +3 do
      Event.create(
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
    catch_event = create_event_with_times( Time.now, (Time.now + 11.seconds), Catch)
    throw_event = create_event_with_times( Time.now, (Time.now + 23.seconds), Throw)

    assert_equal catch_event.ending_at, throw_event.expiration_time
  end

  test "first event in pass sets lifetime" do
    sweep_in_event  = create_event_with_times( Time.now, (Time.now + 11.seconds), SweepIn)
    sweep_out_event = create_event_with_times( Time.now, (Time.now + 23.seconds), SweepOut)

    assert_equal sweep_in_event.ending_at, sweep_out_event.expiration_time
  end

  test "expired?" do
    event = create_event_with_times( 14.seconds.ago, 7.seconds.ago, Throw )
    assert event.expired?, "Event should be expired"
  end

  test "no more events in event_group after expired?" do
    catch_event = create_event_with_locations(44.1, 44.5, [], Catch)
    throw_event = create_event_with_locations(44.1, 44.5, [], Throw)
    group_a     = catch_event.event_group

    expire group_a

    next_catch_event = create_event_with_locations(44.1, 44.5, [], Catch)

    assert group_a != next_catch_event.event_group
  end

  test "creating a drop event auto creates an upload as well" do
    assert_difference "Upload.count", +1 do
      create_event_with_locations( 52.0, 13.0, [], Drop )
    end
  end

  test "first (Legacy)Throw on location creates new peer group" do
    assert_difference "EventGroup.count", +1 do
      create_event_with_locations(44.1, 44.5, [], Throw)
    end
    assert_not_nil Event.last.event_group
  end

  test "following peers join exisiting peer group instead of creating one" do
    event = create_event_with_locations(44.1, 44.5, [], Throw)
    assert_no_difference "EventGroup.count" do
      create_event_with_locations(44.1, 44.5, [], Catch)
    end

    assert_not_nil event.event_group
  end

  test "status and status response is a hash" do
    event_a = create_event_with_locations(44.1, 44.5, [], Throw)
    event_b = create_event_with_locations(44.1, 44.5, [], Catch)

    assert event_a.info
    assert event_a.info.class == Hash
  end

  test "current_state :collision" do
    event_a = create_event_with_locations(44.1, 44.5, [], SweepOut)
    event_b = create_event_with_locations(44.1, 44.5, [], SweepOut)

    assert_equal :collision, event_a.reload.info[:state]
  end

  test "current_state :waiting" do
    event_a = create_event_with_locations(44.1, 44.5, [], SweepOut)
    event_b = create_event_with_locations(44.1, 44.5, [], SweepIn)

    assert_equal :waiting, event_b.reload.info[:state]
  end

  test "current_state :ready" do
    event_a = create_event_with_locations(44.1, 44.5, [], SweepOut)
    event_b = create_event_with_locations(44.1, 44.5, [], SweepIn)

    expire event_a.event_group

    assert_equal :ready, event_a.info[:state]
    assert_equal :ready, event_b.info[:state]
  end

  test "collision state propagates to all distribute participants" do
    Event.delete_all
    event_a = create_event_with_locations(44.1, 44.5, [], Throw)
    event_b = create_event_with_locations(44.1, 44.5, [], Catch)
    event_c = create_event_with_locations(44.1, 44.5, [], Throw)
    event_d = create_event_with_locations(44.1, 44.5, [], Catch)

    Event.all.each {|e| e.api_version=1; e.save}

    assert event_d.reload.legacy?
    assert_equal ["waiting"], Event.all.map(&:state).uniq

    info = event_d.info

    assert_equal ["collision"], Event.all.map(&:state).uniq
  end

  test "no_seeders state propagates to all distribute participants" do
    Event.delete_all
    event_b = create_event_with_locations(44.1, 44.5, [], Catch)
    event_d = create_event_with_locations(44.1, 44.5, [], Catch)
    Event.all.each {|e| e.api_version=1; e.save}

    assert event_d.reload.legacy?
    assert_equal ["waiting"], Event.all.map(&:state).uniq

    expire EventGroup.last
    info = event_d.info

    assert_equal ["no_seeders"], Event.all.map(&:state).uniq
  end

  test "no_peers state propagates to all distribute participants" do
    Event.delete_all
    event_d = create_event_with_locations(44.1, 44.5, [], Throw)
    Event.all.each {|e| e.api_version=1; e.save}

    assert event_d.reload.legacy?
    assert_equal ["waiting"], Event.all.map(&:state).uniq

    expire EventGroup.last
    info = event_d.info

    assert_equal ["no_peers"], Event.all.map(&:state).uniq
  end

  test "ready state propagates to all distribute participants" do
    Event.delete_all
    event_b = create_event_with_locations(44.1, 44.5, [], Catch)
    event_c = create_event_with_locations(44.1, 44.5, [], Catch)
    event_d = create_event_with_locations(44.1, 44.5, [], Throw)
    Event.all.each {|e| e.api_version=1; e.save}

    assert event_d.reload.legacy?
    assert_equal ["waiting"], Event.all.map(&:state).uniq

    expire EventGroup.last
    info = event_d.info

    assert_equal ["ready"], Event.all.map(&:state).uniq
  end

  test "for endless waiting state" do

    event = Throw.create(
      "starting_at"       => "Tue Apr 13 09:00:22 UTC 2010".to_time,
      "ending_at"         => "Tue Apr 13 09:00:29 UTC 2010".to_time,
      "latitude"          => 45.444305,
      "longitude"         => 8.627495,
      "event_group_id"    => 306763,
      "location_accuracy" => 253.846294,
      "pairing_mode"      => nil,
      "user_agent"        => "Hoccer /1.0.2 iPhone",
      "state"             => "waiting",
      "api_version"       => 1
    )
    event.update_attribute(:api_version, 1)
    event.reload

    assert_equal :waiting, event.state.to_sym
    assert event.expired?
    assert_equal :waiting, event.reload.state.to_sym
    assert_equal :no_peers, event.current_state
    assert_equal :no_peers, event.reload.state.to_sym
    event.info[:state]
    # State changed
    assert_equal :no_peers, event.reload.state.to_sym
  end

end
