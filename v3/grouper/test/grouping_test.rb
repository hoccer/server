$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), ".."))
require 'helper'
require 'lib/environment'

class ExhibitTest < Test::Unit::TestCase

  def new_location
    @gps ||= [13, 52]
    @gps.map! { |element| element += 1 } 

    operand = (rand(2) % 2) == 0 ? +1 : -1
    {
      :gps => {
        :longitude => (@gps[0] + (rand/50 * operand)),
        :latitude  => (@gps[1] + (rand/50 * operand)),
        :accuracy  => 100.0
      }
    }
  end
  
  def teardown 
    Environment.delete_all
  end
  
  test 'grouping two clients' do
    location = new_location
    location.merge!(:client_uuid => 1)

    a  = Environment.create(location)
    assert a[:group_id], "should have a group id"
    
    location.merge!(:client_uuid => 2)
    b = Environment.create(location)

    a.reload

    assert_equal b.group.count, 2, "should have grouped environments"   
    assert_equal a.group.count, 2, "should have grouped environments"   
    
    assert_equal a[:group_id], b[:group_id], "group ids should match"

    b.group.each do |element|
      puts element.inspect
      assert_equal 1, a.group.where(:client_uuid => element[:client_uuid]).count
    end
    
    assert_equal b.group, a.group
  end  
  
  test 'not grouping clients' do
    location = new_location
    location.merge!(:client_id => 1)
    a  = Environment.create(location)
    
    location2 = new_location
    location2.merge!(:client_id => 2)
    b = Environment.create(location2)
    
    assert_not_equal a["group_id"], b["group_id"]    
  end  
  
  
end