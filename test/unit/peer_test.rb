require 'test_helper'

class PeerTest < ActiveSupport::TestCase
  
  test "should not create access points if peer is invalid" do
    assert_no_difference "AccessPoint.count" do
      Peer.create(
        :latitude   => 44.1,
        :longitude  => 44.2,
        :accuracy   => 23.0,
        :access_points_attributes => [
          { :bssid => "ffff" },
          { :bssid => "eeee" },
          { :bssid => "aaaa" }
        ]
      )
    end
  end
  
  test "should create 3 accesspoints for valid peer" do
    assert_difference "AccessPoint.count", +3 do
      peer = Peer.create(
        :latitude   => 44.1,
        :longitude  => 44.2,
        :accuracy   => 23.0,
        :gesture    => "pass",
        :access_points_attributes => [
          { :bssid => "ffff" },
          { :bssid => "eeee" },
          { :bssid => "aaaa" }
        ],
        :transfered_content_type => "image/jpeg"
      )
    end
  end
  
  test "find multiple peers based on similiar bssids" do
    peer_1 = create_peer_with_bssids( 52.3, 42.1, 50.0, "pass", true, "bbb", "ccc", "aaa" )
    peer_2 = create_peer_with_bssids( 80.2, 20.2, 50.0, "pass", false, "aaa", "bzb", "czc" )
    peer_3 = create_peer_with_bssids( 14.1, 66.1, 50.0, "pass", false, "aaa", "ccc", "bbb" )
    
    assert_equal 2, Peer.find_all_in_range_of(peer_1).size
    assert_equal 3, PeerGroup.last.peers.count
  end
  
  test "find multiple peers based on similiar real bssids" do
    peer_1 = create_peer_with_bssids( 52.3, 42.1, 50.0, "pass", true,   "00:0f:b5:92:fa:45" )
    peer_2 = create_peer_with_bssids( 80.2, 20.2, 50.0, "pass", false,  "00:22:3f:10:a8:bf", "00:0f:b5:92:fa:45" )
    peer_3 = create_peer_with_bssids( 14.1, 66.1, 50.0, "pass", false,  "00:0f:b5:92:fa:45", "00:22:3f:11:5e:5e" )
    
    assert_equal 2, Peer.find_all_in_range_of(peer_1).size
  end
  
  test "no peers found if too far away and different bssids" do
    peer_1 = create_peer_with_bssids( 52.3, 42.1, 50.0, "pass", true, "aaa", "bbb", "ccc" )
    peer_2 = create_peer_with_bssids( 52.2, 42.2, 50.0, "pass", false, "aba", "bcb", "cac" )
    peer_3 = create_peer_with_bssids( 52.1, 42.1, 50.0, "pass", false, "aab", "bbc", "cca" )
    
    assert_equal 0, Peer.find_all_in_range_of(peer_1).size
  end
  
  test "multiple peers found by location even if bssids differ" do
    peer_1 = create_peer_with_bssids( 52.501077, 13.345116, 80.0, "distribute", true, "aaa", "bbb", "ccc" )
    peer_2 = create_peer_with_bssids( 52.500927, 13.345738, 80.0, "distribute", false, "aba", "bcb", "cac" )
    peer_3 = create_peer_with_bssids( 52.501616, 13.345785, 80.0, "distribute", false, "aab", "bbc", "cca" )
    
    assert_equal 2, Peer.find_all_in_range_of(peer_1).size
  end
  
  test "find peers in range or bssids" do
    peer_1 = create_peer_with_bssids( 52.501077, 13.345116, 80.0, "distribute", true, "aaa", "bbb", "ccc" )
    peer_2 = create_peer_with_bssids( 52.500927, 13.345738, 80.0, "distribute", false, "aba", "bcb", "cac" )
    peer_3 = create_peer_with_bssids( 20.501616, 20.345785, 80.0, "distribute", false, "aaa", "bbc", "cca" )
    
    assert_equal 2, Peer.find_all_in_range_of(peer_1).size
  end
  
  test "another falsification" do
    peer_1 = create_peer_with_bssids( 52.501077, 13.345116, 80.0, "distribute", true, "aaa", "bbb", "ccc" )
    peer_2 = create_peer_with_bssids( 52.500927, 13.345738, 80.0, "distribute", false, "aba", "bcb", "cac" )
    peer_3 = create_peer_with_bssids( 20.501616, 20.345785, 80.0, "distribute", false, "aaa", "bbc", "cca" )
    peer_4 = create_peer_with_bssids( 20.501616, 20.345785, 80.0, "distribute", false, "aab", "bbc", "cca" )
    
    assert_equal 2, Peer.find_all_in_range_of(peer_1).size
  end
  
  test "peer has many bssids" do
    assert_equal [], create_peer( 52.3, 42.1, 50.0, "pass", true ).access_points
  end
  
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
    Peer.create!(
      :latitude   => lat,
      :longitude  => long,
      :accuracy   => acc,
      :gesture    => gesture,
      :seeder     => seeder
    )
  end
  
  
  def create_peer_with_bssids lat, long, acc, gesture, seeder, *bssids
    
    access_points = bssids.map {|bssid| {:bssid => bssid}}
    
    Peer.create!(
      :latitude   => lat,
      :longitude  => long,
      :accuracy   => acc,
      :gesture    => gesture,
      :access_points_attributes => access_points,
      :transfered_content_type => "image/jpeg"
    )
  end
end
