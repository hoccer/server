require 'test_helper'

class PeersControllerTest < ActionController::TestCase

  test "creating new seeder peergroup and access points" do
    assert_difference "AccessPoint.count", +3 do
      post :create, :peer => {
        :latitude   => 13.44,
        :longitude  => 52.12,
        :accuracy   => 42.0,
        :gesture    => "pass",
        :seeder     => true,
        :bssids     => ["aaaa", "bbbb", "cccc"],
      }
    end
  end

  test "creating new seeder and peer group" do
    assert_difference ["Peer.count", "PeerGroup.count"], +1 do
      post :create, :peer => {
        :latitude   => 13.44,
        :longitude  => 52.12,
        :accuracy   => 42.0,
        :gesture    => "pass",
        :seeder     => true
      }
    end
    
    assert_response :success
    json_response = ActiveSupport::JSON.decode( @response.body )
    assert_equal json_response["peer_uri"], peer_url(:id => Peer.first.uid)
    assert_equal json_response["upload_uri"], upload_url(:id => Upload.first.uid)
  end
  
  test "creating a new seeder and peer group with transfered content_type" do
    assert_difference ["Peer.count", "PeerGroup.count"], +1 do
      post :create, :peer => {
        :latitude   => 13.44,
        :longitude  => 52.12,
        :accuracy   => 42.0,
        :gesture    => "pass",
        :seeder     => true,
        :transfered_content_type => "image/*"
      }
    end
    
    assert_response :success
    json_response = ActiveSupport::JSON.decode( @response.body )
    assert_equal json_response["peer_uri"], peer_url(:id => Peer.first.uid)
    assert_equal json_response["upload_uri"], upload_url(:id => Upload.first.uid)
    
  end
  
  
  test "peers do not receive an upload url upon creation" do
    assert_difference ["Peer.count", "PeerGroup.count"], +1 do
      post :create, :peer => {
        :latitude   => 13.44,
        :longitude  => 52.12,
        :accuracy   => 42.0,
        :gesture    => "pass",
        :seeder     => false
      }
    end
    
    assert_response :success
    json_response = ActiveSupport::JSON.decode( @response.body )
    assert_equal json_response["peer_uri"], peer_url(:id => Peer.first.uid)
    assert_nil json_response["upload_uri"]
  end
  
  test "creating peer without seeder param defaults to seeder=false" do
    post :create, :peer => {
      :latitude   => 13.44,
      :longitude  => 52.12,
      :accuracy   => 42.0,
      :gesture    => "pass"
    }
    
    assert_equal false, Peer.first.seeder
  end
  
  test "querying a peer" do
    peer_a = create_peer( 52.501077, 13.345116, 80.0, "distribute", true)
    peer_b = create_peer( 52.500927, 13.345738, 80.0, "distribute", false)
    PeerGroup.first.expire!
    
    get :show, :id => peer_b.uid
    json_response = ActiveSupport::JSON.decode( @response.body )
    assert_equal json_response["resources"], [upload_url(:id => Upload.first.uid)]
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
