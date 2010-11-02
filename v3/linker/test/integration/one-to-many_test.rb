$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), ".."))
require 'helper'
require 'test_client'
require 'mongo'
require 'net/http'

class TestOneToMany < Test::Unit::TestCase

  test 'one-to-many, one thrower two catcher' do
      client_1 = create_client
      client_2 = create_client
      client_3 = create_client
    
      t1 = Thread.new { client_1.share("one-to-many", { :inline => "foobar" }) }
      t2 = Thread.new { client_2.receive_unthreaded("one-to-many") }
      t3 = Thread.new { client_3.receive_unthreaded("one-to-many") }
                                
      client_3_response = t3.value
      client_2_response = t2.value
      client_1_response = t1.value
    
      assert_equal "200", client_1_response.header.code
      assert_equal "200", client_2_response.header.code
      assert_equal "200", client_3_response.header.code    
                               
      expected = "[{\"inline\":\"foobar\"}]"
    
      assert_equal expected, client_1_response.body
      assert_equal expected, client_2_response.body
      assert_equal expected, client_3_response.body      
    
      client_1.delete_environment
      client_2.delete_environment
      client_3.delete_environment
  end

end
