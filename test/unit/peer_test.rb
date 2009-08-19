require 'test_helper'

class PeerTest < ActiveSupport::TestCase
  
  test "uid is generated on freshly created peers" do
    assert_not_nil peer = create_peer( 52.13, 42.12, 50.0, "pass", true )
    assert_not_nil peer.uid
  end
  
  test "first peer on location creates new peer group" do
    assert_difference "PeerGroup.count", +1 do
      peer = create_peer( 52.13, 42.12, 50.0, "pass", true )
    end
    assert_not_nil Peer.first.peer_group
  end
  
  test "following peers join exisiting peer group instead of creating one" do
    peer = create_peer( 52.131, 42.121, 50.0, "pass", true )
    assert_no_difference "PeerGroup.count" do
      peer = create_peer( 52.131, 42.121, 50.0, "pass", false )
    end
    assert_equal 1, PeerGroup.count
    assert_not_nil Peer.first.peer_group
  end
  
  test "find peers in range of" do
    peer_a = create_peer( 52.501077, 13.345116, 80.0, "distribute", true)
    peer_b = create_peer( 52.500927, 13.345738, 80.0, "distribute", false)
    peer_c = create_peer( 52.505616, 13.348785, 10.0, "distribute", false)

    assert_equal 1, Peer.find_all_in_range_of( peer_a ).length
    assert_equal 1, Peer.find_all_in_range_of( peer_b ).length
    assert_equal 0, Peer.find_all_in_range_of( peer_c ).length
  end
  
  test "find peer in range of" do
    peer_a = create_peer( 52.501077, 13.345116, 80.0, "distribute", true)
    peer_b = create_peer( 52.500927, 13.345738, 80.0, "distribute", false)
    peer_c = create_peer( 52.505616, 13.348785, 10.0, "distribute", false)
    
    assert_equal peer_a, Peer.find_in_range_of( peer_b )
    assert_equal peer_b, Peer.find_in_range_of( peer_a )
    assert_nil Peer.find_in_range_of( peer_c )
  end
  
  test "first seeder with seeder first" do
    peer_a = create_peer( 52.501077, 13.345116, 80.0, "distribute", true)
    assert peer_a.first_seeder?
    
    peer_b = create_peer( 52.500927, 13.345738, 80.0, "distribute", false)
    assert !peer_b.first_seeder?
  end
  
  test "first seeder with seeder last" do  
    peer_c = create_peer( 32.501077, 43.345116, 80.0, "distribute", false)
    assert !peer_c.first_seeder?
    
    peer_d = create_peer( 32.500927, 43.345738, 80.0, "distribute", true)
    assert peer_d.first_seeder?
  end
  
  test "first seeder with all seeders" do
    peer_e = create_peer( 72.501077, 93.345116, 80.0, "exchange", true)
    assert peer_e.first_seeder?
    
    peer_f = create_peer( 72.500927, 93.345738, 80.0, "exchange", true)
    assert !peer_f.first_seeder?
    
    peer_g = create_peer( 72.501077, 93.345116, 80.0, "exchange", true)
    assert !peer_g.first_seeder?
    
    peer_h = create_peer( 72.500927, 93.345738, 80.0, "exchange", true)
    assert !peer_h.first_seeder?
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
