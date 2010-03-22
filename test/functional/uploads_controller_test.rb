require 'test_helper'
require 'digest/md5'

class UploadsControllerTest < ActionController::TestCase
  
  test "updating an upload without supplied content_type" do
    Upload.create :uuid => "23"
    
    tmpfile = File.new(Rails.root.join("test", "fixtures", "upload_test.jpg"))
    
    put( 
      :update,
      :id => 23,
      :upload => {:attachment => tmpfile}
    )
    
    assert_equal "image/jpeg", Upload.find_by_uuid("23").attachment.content_type
  end
  
  test "sending an upload with legacy transfered_content_type which should be ignored" do
    Upload.create :uuid => "23"
    
    tmpfile = File.new(Rails.root.join("test", "fixtures", "upload_test.jpg"))
    
    put( 
      :update,
      :id => 23,
      :upload => {
        :attachment => tmpfile, 
        :transfered_content_type => "image/png"
      }
    )
    
    assert_equal "image/jpeg", Upload.find_by_uuid("23").attachment.content_type
  end
  
  test "uploading a vcard with broken newlines" do
    vcard_path = Rails.root.join("test", "fixtures", "test.vcf")
    
    vcard_content = File.open(vcard_path) {|f| f.read}
    
    digest_before_processing = Digest::MD5.hexdigest(vcard_content)
    
    assert_equal 0, vcard_content.scan(/\r\n/).length
    
    upload = Upload.create( :uuid => "23" )
    
    tmpfile = File.new(Rails.root.join("test", "fixtures", "test.vcf"))
    
    put( 
      :update,
      :upload => {:attachment => tmpfile},
      :id => upload.uuid
    )
    
    upload.reload
    
    # TODO Find out why its not working
    #processed_vcard_path = Rails.root.join("public", upload.attachment.url(:processed))
    
    processed_vcard_path = File.join(
      RAILS_ROOT, "public", upload.attachment.url(:processed).sub(/\?\d+$/, "")
    )
    
    assert File.exist?(processed_vcard_path)
    processed_vcard_content = File.open(processed_vcard_path) {|f| f.read}
    assert_equal 5, processed_vcard_content.scan(/\r\n/).length
    
    digest_after_processing = Digest::MD5.hexdigest(processed_vcard_content)
    assert digest_before_processing != digest_after_processing
  end
  
  test "verify that uploads other than vcard stay untouched" do
    Upload.create :uuid => "23"
    
    tmpfile = File.new(
      Rails.root.join("test", "fixtures", "upload_test.jpg")
    )
    
    digest_before_processing = Digest::MD5.hexdigest(tmpfile.read)

    put( 
      :update,
      :upload => {:attachment => tmpfile},
      :id => Upload.last.uuid
    )
    
    digest_after_processing = Digest::MD5.hexdigest(
      File.read(Upload.last.attachment.path)
    )
    assert_equal digest_before_processing, digest_after_processing
  end
  
  test "fetching an upload without an attachment" do
    assert event = create_event_with_times( Time.now, 7.seconds.from_now, SweepOut)
    assert event.upload
        
    get :show, :id => event.upload.uuid
    assert_response 202
  end
  
  test "fetching an upload with an attachment" do
    assert event = create_event_with_times( Time.now, 7.seconds.from_now, SweepOut)

    attachment = File.new(
      Rails.root.join("test", "fixtures", "upload_test.jpg")
    )

    put(
      :update,
      :upload => {:attachment => attachment},
      :id => Upload.last.uuid
    )
    
    get :show, :id => event.upload.uuid
    assert_response 200
  end
  
  test "uploading a html file" do
    assert event = create_event_with_times( Time.now, 7.seconds.from_now, SweepOut)
    
    attachment = File.new(Rails.root.join("test", "fixtures", "test.html"))
    
    put(
      :update,
      :upload => {:attachment => attachment},
      :id => Upload.last.uuid
    )
    
    get :show, :id => event.upload.uuid
    assert_response 200
  end
  
  test "uploading a zip file" do
    assert event = create_event_with_times( Time.now, 7.seconds.from_now, SweepOut)
    
    attachment = File.new(Rails.root.join("test", "fixtures", "test.zip"))
    
    put(
      :update,
      :upload => {:attachment => attachment},
      :id => Upload.last.uuid
    )
    
    get :show, :id => event.upload.uuid
    assert_response 200
  end
  
end
