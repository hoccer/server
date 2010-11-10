$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), ".."))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__)))
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
        :accuracy  => 100
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
      new_environmnent( :longitude => 13.420, :latitude => 52.522, :accuracy => 35 )
    )

    env_2 = Environment.create(
      new_environmnent( :longitude => 13.422, :latitude => 52.522, :accuracy => 35 )
    )

    env_3 = Environment.create(
      new_environmnent( :longitude => 13.424, :latitude => 52.522, :accuracy => 35 )
    )

    assert_equal 2, env_1.nearby.size
    assert env_1.nearby.include? env_1
    assert env_1.nearby.include? env_2

    env_1.reload
    env_2.reload
    env_3.reload

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
    
    env_1.update_attributes( :gps => {
        :timestamp => 12345678909,
        :latitude  => 52.522,
        :longitude => 13.420,
        :accuracy  => 100
    })
    
    assert_equal "longitude", env_1.gps.keys[0]
    # assert_
  end

  test 'pairing via bssids' do
    environment_1 = new_location
    environment_1 = environment_1.merge(
      :bssids => ["00:1a:b2:be:1e:c9", "00:00:00:00:00:01"]
    )

    environment_2 = new_environmnent(
      :longitude => 13.0,
      :latitude  => 52.0,
      :accuracy  => 100
    )

    environment_2 = environment_2.merge(
      :bssids => ["00:1a:b2:be:1e:c9", "00:00:00:00:00:02"]
    )

    env_1 = Environment.create environment_1
    env_2 = Environment.create environment_2

    assert_equal 2, env_2.nearby_bssids.size
  end

  test 'pairing via bssids and gps' do
    env_1 = Environment.create(
      new_environmnent( :longitude => 13.420, :latitude => 52.522, :accuracy => 35 )
    )

    env_2 = Environment.create(
      new_environmnent( :longitude => 13.422,
                        :latitude => 52.522,
                        :accuracy => 35
      ).merge( {:bssids => ["00:1a:b2:be:1e:c9", "00:00:00:00:00:01"] })
    )


    env_3 = Environment.create(
      { :bssids => ["00:1a:b2:be:1e:c9", "00:00:00:00:00:02"] }
    )

    [ env_1, env_2, env_3 ].each { |env| env.reload }

    assert_equal 3, env_1.group.count
    assert_equal 3, env_2.group.count
    assert_equal 3, env_3.group.count
  end

  test "find nearby events with multiple matching bssids" do
    create_env_with_locations(
      32.1,
      10.5,
      ["00:00:00:00:00:01", "00:00:00:00:00:02"]
    )
    create_env_with_locations(
      10.0,
      51.5,
      ["00:00:00:00:00:01", "00:00:00:00:00:02"]
    )

    assert_equal 2, Environment.last.nearby.size
  end

  test "no peers found if too far away and different bssids" do
    create_env_with_locations(
      32.1,
      10.5,
      ["00:00:00:00:00:01", "00:00:00:00:00:02"]
    )
    create_env_with_locations(
      12.1,
      40.5,
      ["00:00:00:00:00:03", "00:00:00:00:00:04"]
    )
    create_env_with_locations(
      32.1,
      20.5,
      ["00:00:00:00:00:05", "00:00:00:00:00:06"]
    )

    assert_equal 1, Environment.first.nearby.size
    assert_equal 1, Environment.last.nearby.size
  end

  test "find peers in range or bssids" do
    create_env_with_locations(
      32.1,
      10.5,
      ["00:00:00:00:00:01", "00:00:00:00:00:02"]
    )
    create_env_with_locations(
      32.1,
      10.5,
      ["00:00:00:00:00:03", "00:00:00:00:00:04"]
    )
    create_env_with_locations(
      22.1,
      20.5,
      ["00:00:00:00:00:01", "00:00:00:00:00:05"]
    )

    assert_equal 3, Environment.last.group.size
  end                                          
  
  test 'not pairing on different bssids and no gps' do
    env_1 = Environment.create(
      {:bssids => ["01:1a:b2:be:1e:c9", "00:00:00:00:00:01"] }
    )

    env_2 = Environment.create(
      { :bssids => ["00:1a:b2:be:1e:c9", "00:00:00:00:00:02"] }
    )

    # [ env_1, env_2 ].each { |env| env.reload }
    
    assert_equal 1, env_1.group.count
    assert_equal 1, env_2.group.count
  end
  
  test 'not pairing bogus environments' do
    env_1 = Environment.create( 'bla' => 'hallo' )
    env_2 = Environment.create( 'wu' => "ha" )
    
    assert_equal 1, env_1.group.count
    assert_equal 1, env_2.group.count
  end
end
