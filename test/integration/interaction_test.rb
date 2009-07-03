require 'test_helper'

class InteractionTest < ActionController::IntegrationTest
  fixtures :all

  test "uploading a file" do
    
    assert_difference ["Location.count", "Gesture.count"], +1 do
      post( 
        "/locations/52,1212;13,4242;42,5/gesture",
        :gesture => {:name => "throw"}
      )
    end
    
    assert_response :success
    assert_equal "throw", Gesture.last.name
    assert_equal Gesture.last.location, Location.last
    
    expected =  '{"uri": "http://www.example.com/locations/52,1212;13,4242;42,5"}'
    assert_equal expected, @response.body
    
    @upload = File.new(
      File.join(RAILS_ROOT, "test", "fixtures", "upload_test.jpg")
    )
    
    post(
      "/locations/52,1212;13,4242;42,5/uploads",
      :upload => {:attachment => @upload}
    )
    
    assert_response :success
  end
  
  
end
