require 'test_helper'

# These tests assure that the hoccer server behavior is consistent
# with https://y60.artcom.de/redmine/wiki/hoccer/Event_Types

class HoccerSpecTest < ActionController::IntegrationTest
  fixtures :all

  # General Operations (possible for all Events)

  test "linking request" do
    %w( throw catch sweep_in sweep_out drop pick ).each do |event_type|
      post events_path, :event => {
        :type               => event_type,
        :latitude           => 52.0,
        :longitude          => 13.0,
        :location_accuracy  => 100.0,
        :starting_at        => Time.now,
        :ending_at          => 7.seconds.from_now,
        :bssids             => ["ffff", "cccc"]
      }

      assert_response 303
      assert_redirected_to event_path( Event.last.uuid )
    end
  end

  test "abort an event" do
    %w( throw catch sweep_in sweep_out drop pick ).each do |event_type|
      post events_path, :event => {
        :type               => event_type,
        :latitude           => 52.0,
        :longitude          => 13.0,
        :location_accuracy  => 100.0,
        :starting_at        => Time.now,
        :ending_at          => 7.seconds.from_now,
        :bssids             => ["ffff", "cccc"]
      }

      delete event_path( Event.last.uuid )
      assert_response 200
      assert_nil Event.last.event_group
    end
  end

  test "uploading a file" do
    test_upload = fixture_file_upload("test_upload.jpeg", "image/jpeg")

    post events_path, :event => {
      :type               => Throw,
      :latitude           => 52.0,
      :longitude          => 13.0,
      :location_accuracy  => 100.0,
      :starting_at        => Time.now,
      :ending_at          => 7.seconds.from_now,
      :bssids             => ["ffff", "cccc"]
    }

    put(
      upload_path( Event.last.upload.uuid ),
      :upload => { :attachment => test_upload },
      :html => { :multipart => true }
    )

    assert_response 200
  end

  # Throw (distributing a file to N catchers)

  test "waiting state" do
    post events_path, :event => {
      :type               => Throw,
      :latitude           => 52.0,
      :longitude          => 13.0,
      :location_accuracy  => 100.0,
      :starting_at        => Time.now,
      :ending_at          => 7.seconds.from_now,
      :bssids             => ["ffff", "cccc"]
    }

    get event_path( Event.last.uuid )
    assert_response 202

    response = ActiveSupport::JSON.decode( @response.body )
    assert_equal "waiting", response["state"]
    expected_keys = %w(
      event_uri state message expires upload_uri peers status_code
    )

    assert_equal expected_keys.sort, response.keys.sort
  end

  test "collision state" do
    post events_path, :event => {
      :type               => Throw,
      :latitude           => 52.0,
      :longitude          => 13.0,
      :location_accuracy  => 100.0,
      :starting_at        => Time.now,
      :ending_at          => 7.seconds.from_now,
      :bssids             => ["ffff", "cccc"]
    }

    post events_path, :event => {
      :type               => Throw,
      :latitude           => 52.0,
      :longitude          => 13.0,
      :location_accuracy  => 100.0,
      :starting_at        => Time.now,
      :ending_at          => 7.seconds.from_now,
      :bssids             => ["ffff", "cccc"]
    }

    EventGroup.last.events.each do |event|
      get event_path( event.uuid )
      assert_response 409

      response = ActiveSupport::JSON.decode( @response.body )
      assert_equal "collision", response["state"]
      expected_keys = %w(
        event_uri state message expires upload_uri peers status_code
      )

      assert_equal expected_keys.sort, response.keys.sort
    end
  end
end
