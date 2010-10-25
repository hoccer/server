$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), ".."))
require 'helper'
require 'ruby-debug'
require 'uuid'
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
      },
      :client_uuid => UUID.generate
    }
  end

  def new_environmnent options = {}
    default_options = {
      :longitude  => 13.420,
      :latitude   => 52.522,
      :timestamp  => Time.now.to_f,
      :accuracy   => 120.0
    }

    options = default_options.merge( options )

    { :client_uuid => UUID.generate, :gps => options }
  end

  def teardown
    Environment.delete_all
  end

  test 'distance calculation' do
    env_1 = Environment.create(
      new_environmnent( :longitude => 13.420, :latitude => 52.522 )
    )

    env_2 = Environment.create(
      new_environmnent( :longitude => 13.422, :latitude => 52.522 )
    )

    env_3 = Environment.create(
      new_environmnent( :longitude => 13.424, :latitude => 52.522 )
    )

    assert_equal env_2, env_1.nearby.first
    assert_equal 2, env_2.nearby.size
    assert_equal env_2, env_3.nearby.first
  end

  test 'grouping two clients' do

    env_1 = Environment.create(
      new_environmnent( :longitude => 13.420, :latitude => 52.522 )
    )

    env_2 = Environment.create(
      new_environmnent( :longitude => 13.420, :latitude => 52.522 )
    )

    assert env_1.reload[:group_id], "should have a group id"
    assert env_2.reload[:group_id], "should have a group id"

    assert_equal env_1.group.count, 2, "should have grouped environments"
    assert_equal env_2.group.count, 2, "should have grouped environments"

    assert_equal env_1[:group_id], env_2[:group_id], "group ids should match"
    assert_equal env_2.group, env_1.group

    assert JSON.parse(env_1.group.to_json)
  end

  test 'chain grouping 3 clients' do

    env_1 = Environment.create(
      new_environmnent( :longitude => 13.420, :latitude => 52.522 )
    )

    env_2 = Environment.create(
      new_environmnent( :longitude => 13.422, :latitude => 52.522 )
    )

    env_3 = Environment.create(
      new_environmnent( :longitude => 13.424, :latitude => 52.522 )
    )

    assert_equal env_2, env_1.nearby.first
    assert_equal 2, env_2.nearby.size
    assert_equal env_2, env_3.nearby.first

    env_1.reload
    env_2.reload
    env_3.reload

    assert_equal 3, env_1.group.count
    assert_equal 3, env_2.group.count
    assert_equal 3, env_3.group.count
  end

  test 'not grouping clients' do
    location = new_location
    a  = Environment.create(location)

    location2 = new_location
    b = Environment.create(location2)

    assert_not_equal a["group_id"], b["group_id"]
  end

  test 'lonley group' do
    location = new_location
    a  = Environment.create(location)
    assert_equal 1, a.group.count,  "should have at least self"
  end

  test 'get newest client update' do
     location = new_location
     Environment.create(location)
     Environment.create(location)
     newest_added = Environment.create(location)

     newest_find = Environment.newest( location[:client_uuid] )

     assert_equal newest_added, newest_find, "should find last added environment"
  end

  test 'reordering of longitude and latitude' do
    env_1 = Environment.create(
      :gps => {
        :latitude  => 52.522,
        :longitude => 13.420,
        :accuracy  => 100
      },
      :client_uuid => "fooobar"
    )

    assert_equal "longitude", env_1.gps.keys[0]
  end
end
