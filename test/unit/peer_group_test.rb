require 'test_helper'

class PeerGroupTest < ActiveSupport::TestCase

  test "first seeder sets expiration time with first peer == seeder" do
    peer_a = create_peer( 52.501077, 13.345116, 80.0, "distribute", true)
    sleep(1)
    peer_b = create_peer( 52.500927, 13.345738, 80.0, "distribute", false)
    
    expected = (peer_a.created_at + 10.seconds)
    assert expected.to_s == peer_b.peer_group.expires_at.to_s
  end
  
  test "first seeder sets expiration time with first peer != seeder" do
    peer_a = create_peer( 52.501077, 13.345116, 80.0, "distribute", false)
    sleep(1)
    peer_b = create_peer( 52.500927, 13.345738, 80.0, "distribute", true)
      
    expected = peer_b.created_at + 10.seconds
    assert expected.to_s == peer_b.peer_group.expires_at.to_s
  end
  
  test "expired?" do
    peer_group = PeerGroup.create( :expires_at => (Time.now + 10.seconds) )
    assert !peer_group.expired?
    
    peer_group = PeerGroup.create( :expires_at => 10.seconds.ago)
    assert peer_group.expired?
  end
  
  test "no more peers after exiration time" do
    assert peer_a = create_peer( 52.501077, 13.345116, 80.0, "distribute", true)
    assert peer_b = create_peer( 52.500927, 13.345738, 80.0, "distribute", false)
    assert_equal 1, PeerGroup.count 
    PeerGroup.first.update_attributes(:expires_at => Time.now)
    assert peer_c = create_peer( 52.500927, 13.345738, 80.0, "distribute", false)
    assert_equal 2, PeerGroup.count
    assert peer_a.peer_group != peer_c.peer_group
  end
  
  test "two peers with different gestures create two different groups" do
    assert create_peer( 52.501077, 13.345116, 80.0, "distribute", true)
    assert create_peer( 52.500927, 13.345738, 80.0, "pass", false)
    assert_equal 2, PeerGroup.count
  end

  test "status and status response is a hash" do
    peer_a = create_peer( 52.501077, 13.345116, 80.0, "distribute", true)
    peer_b = create_peer( 52.500927, 13.345738, 80.0, "distribute", false)
    
    assert peer_a.peer_group.status
    assert peer_a.peer_group.status.class == Hash
  end
  
  test "invalid peer group for pass with two seeders" do
    create_peer( 52.501077, 13.345116, 80.0, "pass", true)
    create_peer( 52.501077, 13.345116, 80.0, "pass", true)
    assert !PeerGroup.first.valid?
  end
  
  test "invalid peer group for pass with two peers" do
    create_peer( 52.501077, 13.345116, 80.0, "pass", false)
    create_peer( 52.501077, 13.345116, 80.0, "pass", false)
    assert !PeerGroup.first.valid?
  end
  
  test "invalid peer group for pass with three peers" do
    create_peer( 52.501077, 13.345116, 80.0, "pass", true)
    create_peer( 52.501077, 13.345116, 80.0, "pass", false)
    create_peer( 52.501077, 13.345116, 80.0, "pass", false)
    assert !PeerGroup.first.valid?
  end
  
  test "current_state :collision" do
    create_peer( 52.501077, 13.345116, 80.0, "pass", true)
    create_peer( 52.501077, 13.345116, 80.0, "pass", true)
    assert_equal :collision, PeerGroup.first.current_state
  end
  
  test "current_state :waiting" do
    create_peer( 52.501077, 13.345116, 80.0, "distribute", true)
    create_peer( 52.500927, 13.345738, 80.0, "distribute", false)
    assert_equal :waiting, PeerGroup.first.current_state
  end
  
  test "current_state :ready" do
    create_peer( 52.501077, 13.345116, 80.0, "distribute", true)
    create_peer( 52.500927, 13.345738, 80.0, "distribute", false)
    PeerGroup.first.update_attributes(:expires_at => Time.now)
    assert_equal :ready, PeerGroup.first.current_state
  end
  
  
  def create_distributed_peer_group
    peer_group = PeerGroup.create
    peer_a = create_peer( 52.501077, 13.345116, 80.0, "distribute", true)
    peer_b = create_peer( 52.500927, 13.345738, 80.0, "distribute", false)
    peer_group.peers << peer_a
    peer_group.peers << peer_b
  end
  
  def create_peer lat, long, acc, gesture, seeder
    Peer.create(
      :latitude   => lat,
      :longitude  => long,
      :accuracy   => acc,
      :gesture    => gesture,
      :seeder     => seeder
    )
  end
end
