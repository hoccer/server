$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), ".."))
require 'helper'
require 'lib/environment'

class ExhibitTest < Test::Unit::TestCase

  def random_location
    operand = (rand(2) % 2) == 0 ? +1 : -1

    {
      :gps => {
        :longitude => (13.414993 + (rand/50 * operand)),
        :latitude  => (52.520817 + (rand/50 * operand)),
        :accuracy  => 100.0
      }
    }
  end
  
  def teardown 
    # Environment.delete_all
  end
  
  test 'grouping two clients' do
    location = random_location
    location.merge(:client_id => 1)
    a  = Environment.create(location)
    puts "created env"
    assert a[:group_id], "should have a group id"
    
    location.merge(:client_id => 2)
    b = Environment.create(location)
    
    assert_equal a[:group_id], b[:group_id]    
  end  
  
  test 'not grouping clients' do
    location = random_location
    location.merge(:client_id => 1)
    a  = Environment.create(location)
    
    location2 = random_location
    location2.merge(:client_id => 2)
    b = Environment.create(location2)
    
    assert_not_equal a["group_id"], b["group_id"]    
  end  
  
  
end