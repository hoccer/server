require 'test_helper'

class UploadsControllerTest < ActionController::TestCase
  test "updating an upload" do
    Upload.create :uid => "23"
    
    tmpfile = File.new(
      File.join(RAILS_ROOT, "test", "fixtures", "upload_test.jpg")
    )
    
    put( 
      :update,
      :upload => {:attachment => tmpfile},
      :id => Upload.last.uid
    )
  end
  
  test "fetching an upload without an attachment" do
    assert peer = Peer.create(
      :latitude   => 13.44,
      :longitude  => 52.12,
      :accuracy   => 42.0,
      :gesture    => "pass",
      :seeder     => true
    )
    
    assert peer.upload
        
    get :show, :id => peer.upload.uid
    assert_response 202
  end
  
  test "fetching an upload with an attachment" do
    assert peer = Peer.create(
      :latitude   => 13.44,
      :longitude  => 52.12,
      :accuracy   => 42.0,
      :gesture    => "pass",
      :seeder     => true
    )

    attachment = File.new(
      File.join(RAILS_ROOT, "test", "fixtures", "upload_test.jpg")
    )

    put(
      :update,
      :upload => {:attachment => attachment},
      :id => Upload.last.uid
    )
    
    get :show, :id => peer.upload.uid
    assert_response 200
  end
end
