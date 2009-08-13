require 'test_helper'

class GesturesControllerTest < ActionController::TestCase
  
  test "no seeding collisions for pass" do
    
    post( :create, :location_id => "52,1212;13,4242;80",
                   :gesture => {:name => "pass"})
    
    assert_response 200
    
    post( :create, :location_id => "52,1212;13,4242;80",
                   :gesture => {:name => "pass"})
    
    assert_response 403
  end
  
  test "no seeding collisions for distribute" do
    
    post( :create, :location_id => "52,1212;13,4242;80",
                   :gesture => {:name => "distribute"})
    
    assert_response 200
    
    post( :create, :location_id => "52,1212;13,4242;80",
                   :gesture => {:name => "distribute"})
    
    assert_response 403
  end
  
  test "many seeding collisions for exchange" do
    post( :create, :location_id => "52,1212;13,4242;80",
                   :gesture => {:name => "exchange"})
    
    assert_response 200
    
    post( :create, :location_id => "52,1212;13,4242;80",
                   :gesture => {:name => "exchange"})
    
    assert_response 200
  end

end
