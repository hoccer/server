require 'test_helper'

class PeersControllerTest < ActionController::TestCase


  test "creating new peer and peer group" do
    assert_difference ["Peer.count", "PeerGroup.count"], +1 do
      post :create, :id => "13,44;52,12;42,0", :gesture => "pass", :role => "seeder"
    end
    
    assert_response :success
    json_response = ActiveSupport::JSON.decode( @response.body )
    assert_equal json_response["peer_uri"], peer_url(:id => Peer.first.uid)
    assert_equal json_response["upload_uri"], upload_url(:id => Upload.first.uid)
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
