require 'test_helper'

class ThrowCatchTest < ActionController::IntegrationTest
  fixtures :all

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
    
    post events_path, :event => {
      :type               => "throw",
      :latitude           => 52.0,
      :longitude          => 13.0,
      :location_accuracy  => 100.0,
      :starting_at        => Time.now,
      :ending_at          => 7.seconds.from_now,
      :bssids             => ["ffff", "cccc"]
    }
    
    assert_equal 1, EventGroup.count
    assert_equal 2, Throw.count 
    assert Event.first.collisions?, "There should definitely be a collision!!!"
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
