$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), ".."))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__)))
require 'helper'

class TestEnvironment < Test::Unit::TestCase

  def setup
    $conn ||= Mongo::Connection.new
    @db   = $conn['hoccer_accounts']
    @coll = @db['accounts']

    accounts = @coll.find(
      'api_key' => {
        '$in' => ['e101e890ea97012d6b6f00163e001ab0', 'b3b03410159c012e7b5a00163e001ab0']
      }
    ).to_a

    if accounts.empty?

      user_1 = {
        "api_key"               => "e101e890ea97012d6b6f00163e001ab0",
        "confirmation_sent_at"  => Time.now-3600,
        "confirmation_token"    => nil,
        "confirmed_at"          => Time.now-3000,
        "email"                 => "foo@bar.com",
        "encrypted_password"    => "$2a$10$nHhXCsjoKaxrWasIUdWrFeiWNz8lwNba2nQJMD6Ci/GTvgU/dU5Qi",
        "password_salt"         => "$2a$10$nHhXCsjoKaxrWasIUdWrFe",
        "shared_secret"         => "3kkLbF66ZqqJSV0NW3rUBxHSudA=",
        "websites"              => [ "https://developer.hoccer.com" ],
        "hoccer_compatible"     => true
      }


      user_2 = {
        "api_key"               => "b3b03410159c012e7b5a00163e001ab0",
        "confirmation_sent_at"  => Time.now-3600,
        "confirmation_token"    => nil,
        "confirmed_at"          => Time.now-3000,
        "email"                 => "bar@foo.com",
        "encrypted_password"    => "$2a$10$nHhXCsjoKaxrWasIUdWrFeiWNz8lwNba2nQJMD6Ci/GTvgU/dU5Qi",
        "password_salt"         => "$2a$10$nHhXCsjoKaxrWasIUdWrFe",
        "shared_secret"         => "3kkLbF66ZqqJSV0NW3rUBxHSudA=",
        "websites"              => [ "https://developer.hoccer.com" ],
        "hoccer_compatible"     => true
      }

      @coll.insert(user_1)
      @coll.insert(user_2)
    end
  end

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

  test 'grouping to clients with different but compatible api_keys' do

    env_1 = Environment.create(
      new_environmnent( :longitude => 13.420, :latitude => 52.522 ).merge(
        :api_key => "b3b03410159c012e7b5a00163e001ab0"
      )
    )

    env_2 = Environment.create(
      new_environmnent( :longitude => 13.420, :latitude => 52.522 ).merge(
        :api_key => "e101e890ea97012d6b6f00163e001ab0"
      )
    )

    assert env_1.hoccer_compatible?, "Should be hoccer-compatible but isn't"
    assert env_2.hoccer_compatible?, "Should be hoccer-compatible but isn't"

    assert env_1.reload[:group_id], "should have a group id"
    assert env_2.reload[:group_id], "should have a group id"

    assert_equal env_1.reload[:group_id], env_2.reload[:group_id]

    assert env_1.hoccer_compatible_api_keys.include?( env_1.api_key )
    assert env_2.hoccer_compatible_api_keys.include?( env_2.api_key )

    assert_equal env_1.reload.group.count, 2
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
  
  test 'grouping selected clients' do
    env_1 = Environment.create(
      new_environmnent().merge({
        :client_uuid => '1',
        :selected_clients => ['2']
      })
    )

    env_2 = Environment.create(
      new_environmnent().merge({
        :client_uuid => '2',
        :selected_clients => ['1', '3']
      })
    )
    
    env_3 = Environment.create(
      new_environmnent().merge({
        :client_uuid => '3',
        :selected_clients => ['1', '2']
      })
    )
    
    env_1.reload
    env_2.reload
    env_3.reload

    assert_equal 2, env_1.group.count
    assert_equal 3, env_2.group.count
    assert_equal 2, env_3.group.count
  end
  
  test 'grouping selected clients with unselected clients' do
    env_1 = Environment.create(
      new_environmnent().merge({
        :client_uuid => '1',
        :selected_clients => ['2']
      })
    )

    env_2 = Environment.create(
      new_environmnent().merge({
        :client_uuid => '2',
        :selected_clients => ['1', '3']
      })
    )
    
    env_3 = Environment.create(
      new_environmnent().merge({
        :client_uuid => '3',
      })
    )
    
    env_1.reload
    env_2.reload
    env_3.reload

    assert_equal 2, env_1.group.count
    assert_equal 3, env_2.group.count
    assert_equal 3, env_3.group.count
  end
  

  test 'grouping clients with ultra precise locations standing near by' do

    location = new_location
    location[:gps][:accuracy] = 1;
    env_1 = Environment.create(location)

    # move second client ~150 to the away from first client
    location[:gps][:longitude] += 0.0014;
    location[:client_uuid] = UUID.generate
    env_2 = Environment.create(location)

    assert env_1.reload[:group_id], "should have a group id"
    assert env_2.reload[:group_id], "should have a group id"

    assert_equal env_1.group.count, 2, "should have grouped environments"
    assert_equal env_2.group.count, 2, "should have grouped environments"
    assert_equal env_1[:group_id], env_2[:group_id], "group ids should match"
    assert_equal env_2.group, env_1.group
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

  test 'deleting client in group' do
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
    
    env_2.delete
    env_1.reload
    env_3.reload

    assert_equal 2, env_1.group.count
    assert_equal 2, env_3.group.count    
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
      :wifi => { :bssids => ["00:1a:b2:be:1e:c9", "00:00:00:00:00:01"], :timestamp => Time.now.to_f }
    )

    environment_2 = new_environmnent(
      :longitude => 13.0,
      :latitude  => 52.0,
      :accuracy  => 100
    )

    environment_2 = environment_2.merge(
      :wifi => {:bssids => ["00:1a:b2:be:1e:c9", "00:00:00:00:00:02"], :timestamp => Time.now.to_f }
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
      ).merge( :wifi => { :bssids => ["00:1a:b2:be:1e:c9", "00:00:00:00:00:01"], :timestamp => Time.now.to_f })
    )


    env_3 = Environment.create(
      { :wifi => {:bssids => ["00:1a:b2:be:1e:c9", "00:00:00:00:00:02"], :timestamp => Time.now.to_f } }
    )

    [ env_1, env_2, env_3 ].each { |env| env.reload }

    assert_equal 3, env_1.group.count
    assert_equal 3, env_2.group.count
    assert_equal 3, env_3.group.count
  end

  test "find nearby environments with multiple matching bssids" do
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

  test 'grouping by only providing bssids' do
    env_1 = Environment.create(
      { :wifi => {:bssids => ["01:1a:b2:be:1e:c9", "00:00:00:00:00:01"], :timestamp => Time.now.to_f} }
    )

    env_2 = Environment.create(
      { :wifi => {:bssids => ["01:1a:b2:be:1e:c9"], :timestamp => Time.now.to_f } }
    )

    assert_equal 2, Environment.last.group.size
  end

  test 'grouping by providing short and long bssid variants' do
    env_android = Environment.create(
      { :wifi => {:bssids => ["01:0a:b2:f0:1e:09"], :timestamp => Time.now.to_f} }
    )

    env_ios = Environment.create(
      { :wifi => {:bssids => ["1:a:b2:f0:1e:9"], :timestamp => Time.now.to_f } }
    )

    assert_equal 2, Environment.last.group.size
  end

  test 'grouping by providing upper and lowercase bssid variants' do
    env_android = Environment.create(
      { :wifi => {:bssids => ["01:0a:b2:f0:1e:09"], :timestamp => Time.now.to_f} }
    )

    env_ios = Environment.create(
      { :wifi => {:bssids => ["01:0A:B2:f0:1E:09"], :timestamp => Time.now.to_f } }
    )

    assert_equal 2, Environment.last.group.size
  end

  test 'grouping uppercase bssids' do
    env_android = Environment.create(
      { :wifi => {:bssids => ["01:0A:B2:F0:1E:09"], :timestamp => Time.now.to_f} }
    )

    env_ios = Environment.create(
      { :wifi => {:bssids => ["01:0A:B2:f0:1E:09"], :timestamp => Time.now.to_f } }
    )

    assert_equal 2, Environment.last.group.size
  end

  test 'not pairing on different bssids and no gps' do
    env_1 = Environment.create(
      { :wifi => {:bssids => ["01:1a:b2:be:1e:c9", "00:00:00:00:00:01"], :timestamp => Time.now.to_f} }
    )

    env_2 = Environment.create(
      { :wifi => {:bssids => ["00:1a:b2:be:1e:c9", "00:00:00:00:00:02"], :timestamp => Time.now.to_f } }
    )

    [ env_1, env_2 ].each { |env| env.reload }

    assert_equal 1, env_1.group.count
    assert_equal 1, env_2.group.count
  end

  test 'not pairing bogus environments' do
    env_1 = Environment.create( 'bla' => 'hallo' )
    env_2 = Environment.create( 'wu' => "ha" )

    assert_equal 1, env_1.group.count
    assert_equal 1, env_2.group.count
  end

  test 'grouping by only providing coarse network data' do
    env_1 = Environment.create({:network => {
        :longitude => 51.11, :latitude  => 14.153,
        :accuracy  => 10000}
      }
    )

    env_2 = Environment.create({:network => {
        :longitude => 51.11, :latitude  => 14.154, :accuracy  => 10000}
      }
    )

    assert_equal 2, Environment.last.group.size
  end

  test 'grouping gps location with network location' do
    env_1 = Environment.create({
      :gps => {
        :longitude => 51.446367, :latitude  => 14.153577778,
        :accuracy  => 100}
      })

    env_2 = Environment.create({
      :network => {
        :longitude => 51.451222, :latitude  => 14.15444, :accuracy  => 10000}
      })

    assert_equal 2, Environment.last.group.size
  end


  test 'grouping by providing wrong and old gps but fresh network location' do
    env_1 = Environment.create({
      :gps => {
        :longitude => 51.446367, :latitude  => 14.153577778,
        :accuracy  => 100, :timestamp => (Time.now - 1.hour).to_f},
      :network => {
        :longitude => 51.114, :latitude  => 14.153,
        :accuracy  => 10000, :timestamp => (Time.now - 1.hour).to_f}
      })

    env_2 = Environment.create({:gps => {
        :longitude => 51.11222, :latitude  => 14.15444, :accuracy  => 100}
      }
    )

    assert_equal 2, Environment.last.group.size
  end  
end
