require 'test_helper'
require 'digest/md5'

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
  
  test "uploading a vcard with broken newlines" do
    vcard_path = File.join(RAILS_ROOT, "test", "fixtures", "test.vcf")
    
    vcard_content = File.open(vcard_path) {|f| f.read}
    
    digest_before_processing = Digest::MD5.hexdigest(vcard_content)
    
    assert_equal 0, vcard_content.scan(/\r\n/).length
    
    upload = Upload.create( :uid => "23" )
    
    tmpfile = File.new(
      File.join(RAILS_ROOT, "test", "fixtures", "test.vcf")
    )
    
    put( 
      :update,
      :upload => {:attachment => tmpfile},
      :id => upload.uid
    )
    
    upload.reload
    
    processed_vcard_path = File.join(
      RAILS_ROOT, "public", upload.attachment.url(:processed)
    )
    
    assert File.exist?(processed_vcard_path)
    processed_vcard_content = File.open(processed_vcard_path) {|f| f.read}
    assert_equal 5, processed_vcard_content.scan(/\r\n/).length
    
    digest_after_processing = Digest::MD5.hexdigest(processed_vcard_content)
    assert digest_before_processing != digest_after_processing
  end
  
  test "verify that uploads other than vcard stay untouched" do
    Upload.create :uid => "23"
    
    tmpfile = File.new(
      File.join(RAILS_ROOT, "test", "fixtures", "upload_test.jpg")
    )
    
    digest_before_processing = Digest::MD5.hexdigest(tmpfile.read)

    put( 
      :update,
      :upload => {:attachment => tmpfile},
      :id => Upload.last.uid
    )
    
    digest_after_processing = Digest::MD5.hexdigest(
      File.read(Upload.last.attachment.path)
    )
    assert_equal digest_before_processing, digest_after_processing
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
