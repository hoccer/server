require 'test_helper'

class InteractionTest < ActionController::IntegrationTest
  
  test "pairing by bssids" do
    
    assert_equal 0, PeerGroup.count
    
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
    
    assert_equal 1, PeerGroup.count
    assert_equal 2, PeerGroup.first.peers.count
    
    PeerGroup.first.expire!
    
    assert_equal 200, PeerGroup.first.status[:status_code]
  end
  
  
  
  
end
