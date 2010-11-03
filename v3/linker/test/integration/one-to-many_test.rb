$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), ".."))
require 'helper'
require 'test_client'
require 'mongo'
require 'net/http'

class TestOneToMany < Test::Unit::TestCase
     
  def setup 
    db = Mongo::Connection.new.db('hoccer_development')
    coll = db.collection('environments')
    coll.remove
  end
  
  test 'two in group - one sender - one receiver' do
    client_1 = create_client
    client_2 = create_client
    
    start_time = Time.now
    t1 = Thread.new { client_1.share("one-to-many", { :inline => "foobar" }) }
    t2 = Thread.new { client_2.receive_unthreaded("one-to-many") }
                              
    client_2_response = t2.value
    client_1_response = t1.value
    
    duration = Time.now - start_time
                               
    assert duration < 0.1, "two clients in group should pair immediatly, but it took #{duration}"
    assert_equal "200", client_1_response.header.code
    assert_equal "200", client_2_response.header.code
                             
    expected = "[{\"inline\":\"foobar\"}]"
  
    assert_equal expected, client_1_response.body
    assert_equal expected, client_2_response.body

    client_1.delete_environment
    client_2.delete_environment
  end
  
  test 'one-to-many, one thrower two catcher' do
    client_1 = create_client
    client_2 = create_client
    client_3 = create_client
  
    t1 = Thread.new { client_1.share("one-to-many", { :inline => "foobar" }) }
    t2 = Thread.new { client_2.receive_unthreaded("one-to-many") }
    sleep(2)
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
      
  test 'one-to-many, two thrower one catcher' do
    client_1 = create_client
    client_2 = create_client
    client_3 = create_client
  
    t1 = Thread.new { client_1.share("one-to-many", { :inline => "foobar" }) }
    sleep(1)
    t3 = Thread.new { client_3.receive_unthreaded("one-to-many") }
    sleep(1)
    t2 = Thread.new { client_2.share("one-to-many", { :inline => "barbaz"}) }
           
    client_3_response = t3.value
    client_2_response = t2.value
    client_1_response = t1.value
  
    assert_equal "409", client_1_response.header.code
    assert_equal "409", client_2_response.header.code
    assert_equal "409", client_3_response.header.code    
  
    client_1.delete_environment
    client_2.delete_environment
    client_3.delete_environment
  end


end
