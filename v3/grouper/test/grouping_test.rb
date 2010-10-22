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
        :timestamp => Time.now.to_f,
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
    assert_equal b.group, a.group

    assert JSON.parse(a.group.to_json)
  end

  test 'not grouping clients' do
    location = new_location
    location.merge!(:client_uuid => 1)
    a  = Environment.create(location)

    location2 = new_location
    location2.merge!(:client_uuid => 2)
    b = Environment.create(location2)

    assert_not_equal a["group_id"], b["group_id"]
  end

  test 'lonley group' do
    location = new_location
    location.merge!(:client_uuid => 1)
    a  = Environment.create(location)

    assert_equal a.group.count, 1, "should have at least self"
  end

  test 'get newest client update' do
     location = new_location
     location.merge!(:client_uuid => 1)
     Environment.create(location)

     location = new_location
     location.merge!(:client_uuid => 1)
     Environment.create(location)

     location = new_location
     location.merge!(:client_uuid => 1)
     newest_added = Environment.create(location)

     newest_find = Environment.newest 1

     assert_equal newest_added, newest_find, "should find last added environment"
  end



end
