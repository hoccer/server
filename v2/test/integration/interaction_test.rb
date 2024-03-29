require 'test_helper'

class InteractionTest < ActionController::IntegrationTest

  test "deleting an event rejoining an event group afterwards" do
    post events_path, :event => {
      :type               => "throw",
      :latitude           => 52.0,
      :longitude          => 13.0,
      :location_accuracy  => 100.0,
      :starting_at        => Time.now,
      :ending_at          => 7.seconds.from_now,
      :bssids             => ["ffff", "cccc"]
    }

    throw_event = Event.last

    post events_path, :event => {
      :type               => "catch",
      :latitude           => 52.0,
      :longitude          => 13.0,
      :location_accuracy  => 100.0,
      :starting_at        => Time.now,
      :ending_at          => 7.seconds.from_now,
      :bssids             => ["ffff", "cccc"]
    }

    catch_event_a = Event.last

    post events_path, :event => {
      :type               => "catch",
      :latitude           => 52.0,
      :longitude          => 13.0,
      :location_accuracy  => 100.0,
      :starting_at        => Time.now,
      :ending_at          => 7.seconds.from_now,
      :bssids             => ["ffff", "cccc"]
    }

    catch_event_b = Event.last

    delete event_path( :id => catch_event_a.uuid )

    assert_nil    catch_event_a.reload.event_group
    assert_equal  2, throw_event.event_group.events.count

    post events_path, :event => {
      :type               => "catch",
      :latitude           => 52.0,
      :longitude          => 13.0,
      :location_accuracy  => 100.0,
      :starting_at        => Time.now,
      :ending_at          => 7.seconds.from_now,
      :bssids             => ["ffff", "cccc"]
    }

    assert_equal 3, throw_event.event_group.events.count
    assert_equal Event.last.event_group, throw_event.event_group
  end

  test "aborted polling results in waiting state after expiring" do
    post events_path, :event => {
      :type               => "throw",
      :latitude           => 52.0,
      :longitude          => 13.0,
      :location_accuracy  => 100.0,
      :starting_at        => Time.now,
      :ending_at          => 7.seconds.from_now,
      :bssids             => ["ffff", "cccc"]
    }

    get event_path(:id => Event.last.uuid)
    assert_response 202

    sleep(1)

    get event_path(:id => Event.last.uuid)
    assert_response 202 

    expire EventGroup.last
    assert Event.last.expired?

    assert_equal "waiting", Event.last.state
  end
  
  test "pairing by bssids" do
    EventGroup.delete_all
    
    assert_equal 0, EventGroup.count
    
    post peers_path, :peer => {
      :latitude   => 13.44,
      :longitude  => 52.12,
      :accuracy   => 42.0,
      :gesture    => "distribute",
      :seeder     => true,
      :bssids     => [
        "00:22:3f:10:a8:bf",
        "00:50:7f:33:eb:c4",
        "00:22:3f:11:5e:5e",
        "00:0f:b5:92:fa:31",
        "00:0f:b5:92:fa:45",
        "00:0f:b5:92:fb:21"
      ],
    }
    
    sleep(2)
    
    post peers_path, :peer => {
      :latitude   => 20.44,
      :longitude  => 30.12,
      :accuracy   => 42.0,
      :gesture    => "distribute",
      :seeder     => false,
      :bssids     => [
        "00:22:3f:11:5e:5e",
        "00:22:3f:10:a8:bf",
        "00:50:7f:33:eb:c4",
        "00:0f:b5:92:fa:45",
        "00:0f:b5:92:fa:31",
        "00:0f:b5:92:fb:21",
        "00:1d:73:73:c8:7c",
        "00:1f:3f:d6:5a:76",
        "00:19:cb:9e:be:de",
        "00:11:6b:24:d1:20"
      ],
    }

    assert_equal 1, EventGroup.count
    assert_equal 2, EventGroup.first.events.count
        
    assert_response :success
  end
  
  test "multipart content type prefered to uploading file extension" do
    post peers_path, :peer => {
      :latitude   => 20.44,
      :longitude  => 30.12,
      :accuracy   => 42.0,
      :gesture    => "distribute",
      :seeder     => true }
    
    assert_equal 200, status
        
    border = "ycKtoN8VURwvDC4sUzYC9Mo7l0IVUyDDVf"
    multipart  = "--#{border}\r\n"
    multipart << "Content-Disposition: form-data; name=\"upload[attachment]\" "
    multipart << "filename=\"test.ogg\"\r\n"
    multipart << "Content-Type: audio/mpeg\r\n"
    multipart << "Content-Transfer-Encoding: binary\r\n\r\n"
    multipart << "1234567890"
    multipart << "\r\n--#{border}--\r\n"
    
    response_body = ActiveSupport::JSON.decode(@response.body)
    
    put( response_body["upload_uri"],
      multipart,
      { "Content-Type" => "multipart/form-data; boundary=#{border}" }
    )

    assert_response 200
    assert_equal "text/plain", Upload.last.attachment_content_type
  end
  
  test "uploading an image file with broken mimetype" do
    post peers_path, :peer => {
      :latitude   => 20.44,
      :longitude  => 30.12,
      :accuracy   => 42.0,
      :gesture    => "distribute",
      :seeder     => true
    }
    
    assert_equal 200, status
        
    border = "ycKtoN8VURwvDC4sUzYC9Mo7l0IVUyDDVf"
    multipart  = "--#{border}\r\n"
    multipart << "Content-Disposition: form-data; name=\"upload[attachment]\" "
    multipart << "filename=\"test.jpg\"\r\n"
    multipart << "Content-Type: image/*\r\n"
    multipart << "Content-Transfer-Encoding: binary\r\n\r\n"
    multipart << "1234567890"
    multipart << "\r\n--#{border}--\r\n"
    
    response_body = ActiveSupport::JSON.decode(@response.body)
    
    put( response_body["upload_uri"],
      multipart,
      { "Content-Type" => "multipart/form-data; boundary=#{border}" }
    )

    assert_response 200
    assert_equal "text/plain", Upload.last.attachment_content_type
    
    post peers_path, :peer => {
      :latitude   => 20.44,
      :longitude  => 30.12,
      :accuracy   => 42.0,
      :gesture    => "distribute",
      :seeder     => false,
    }
    
    expire EventGroup.last

    get peer_path( Event.last.uuid )
    assert_response :success
    
  end
  
  
  
end
