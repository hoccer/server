require 'test_helper'

class ThrowCatchTest < ActionController::IntegrationTest
  fixtures :all

  test "throw catch" do

    Event.delete_all
    EventGroup.delete_all

    # 1. Create Throw Event

    post events_path, :event => {
      :type               => "throw",
      :latitude           => 52.0,
      :longitude          => 13.0,
      :location_accuracy  => 100.0,
      :starting_at        => Time.now,
      :ending_at          => 7.seconds.from_now,
      :bssids             => ["ffff", "cccc"]
    }

    assert_response :redirect
    follow_redirect!

    throw_event = Event.last
    upload      = Upload.last

    throw_json_response = ActiveSupport::JSON.decode( @response.body )
    assert_equal upload_url(upload.uuid), throw_json_response["upload_uri"]

    # 2. Upload a file

    test_upload = fixture_file_upload("test_upload.jpeg", "image/jpeg")

    put(
      upload_path(:id => upload.uuid),
      :upload => { :attachment => test_upload },
      :html => { :multipart => true }
    )

    throw_event.reload
    assert_equal "test_upload.jpeg", throw_event.upload.attachment.original_filename

    # 3. Create Catch Event

    post events_path, :event => {
      :type               => "catch",
      :latitude           => 52.0,
      :longitude          => 13.0,
      :location_accuracy  => 100.0,
      :starting_at        => Time.now,
      :ending_at          => 7.seconds.from_now,
      :bssids             => ["ffff", "cccc"]
    }

    assert_response :redirect
    follow_redirect!

    catch_event = Event.last
    catch_json_response = ActiveSupport::JSON.decode( @response.body )
    assert_equal nil, catch_json_response["upload_uri"]

    # 4. Poll Events

    get event_path(throw_event.uuid)
    assert_response 202

    get event_path(catch_event.uuid)

#    Due to faster catcher response
    assert_response 200

#    # 5. Expire event_group
#
#    expire throw_event.event_group
#
#    assert throw_event.reload.expired?
#    assert catch_event.reload.expired?
#
#    #6. Poll Events again
#
#    get event_path(throw_event.uuid)
#    assert_response 200
#
#    get event_path(catch_event.uuid)
#    assert_response 200
  end

  test "throw collision" do
    Event.delete_all
    EventGroup.delete_all

    post events_path, :event => {
      :type               => "throw",
      :latitude           => 52.0,
      :longitude          => 13.0,
      :location_accuracy  => 100.0,
      :starting_at        => Time.now,
      :ending_at          => 7.seconds.from_now,
      :bssids             => ["ffff", "cccc"]
    }

    follow_redirect!

    post events_path, :event => {
      :type               => "throw",
      :latitude           => 52.0,
      :longitude          => 13.0,
      :location_accuracy  => 100.0,
      :starting_at        => Time.now,
      :ending_at          => 7.seconds.from_now,
      :bssids             => ["ffff", "cccc"]
    }

    follow_redirect!

    expire EventGroup.last

    assert_equal 1, EventGroup.count
    assert_equal 2, Throw.count
    assert Event.first.collisions?, "There should definitely be a collision!!!"

    get event_path(Event.first.uuid)
    assert_response 409

    get event_path(Event.last.uuid)
    assert_response 409
  end

  test "legacy throw collision" do
    Event.delete_all
    EventGroup.delete_all

    post events_path, :peer => {
      :latitude   => 13.44,
      :longitude  => 52.12,
      :accuracy   => 42.0,
      :gesture    => "distribute",
      :seeder     => true
    }

    post events_path, :peer => {
      :latitude   => 13.44,
      :longitude  => 52.12,
      :accuracy   => 42.0,
      :gesture    => "distribute",
      :seeder     => true
    }

    assert_equal [1,1], Event.all.map(&:api_version)
    assert_equal 1, EventGroup.count
    assert_equal 2, Throw.count
    assert Event.first.collisions?, "There should definitely be a collision!!!"

    get event_path(Event.first.uuid)
  end

  test "legacy throw collision with bssids" do
    Event.delete_all
    EventGroup.delete_all

    post events_path, :peer => {
      :latitude   => 43.44,
      :longitude  => 12.12,
      :accuracy   => 42.0,
      :gesture    => "distribute",
      :seeder     => true,
      :bssids     => [
        "00:22:3f:10:a8:bf",
        "00:50:7f:33:eb:c4"
      ]
    }

    post events_path, :peer => {
      :latitude   => 13.44,
      :longitude  => 52.12,
      :accuracy   => 42.0,
      :gesture    => "distribute",
      :seeder     => true,
      :bssids     => [
        "00:22:3f:10:a8:bf",
        "ff:50:7f:33:eb:c4"
      ]
    }

    assert_equal [1,1], Event.all.map(&:api_version)
    assert_equal 1, EventGroup.count
    assert_equal 2, Throw.count
    assert Event.first.collisions?, "There should definitely be a collision!!!"
    assert_equal :collision, Event.first.info[:state]

    get event_path(Event.first.uuid)
  end
end
