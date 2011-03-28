$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), ".."))
require 'helper'
require 'mongo'
require 'net/http'

class TestOneToMany < Test::Unit::TestCase

  def setup
    db = Mongo::Connection.new.db('hoccer_development')
    coll = db.collection('environments')
    coll.remove
  end

  # test 'two in group - one sender - one receiver' do
  #   client_1 = create_client
  #   client_2 = create_client

  #   start_time = Time.now
  #   t1 = Thread.new { client_1.share("one-to-many", { :inline => "foobar" }) }
  #   t2 = Thread.new { client_2.receive("one-to-many") }

  #   client_2_response = t2.value
  #   client_1_response = t1.value

  #   duration = Time.now - start_time

  #   assert duration < 0.1, "two clients in group should pair immediatly, but it took #{duration}"
  #   assert client_1_response
  #   assert client_2_response

  #   expected = [{"inline" => "foobar"}]

  #   assert_equal expected, client_1_response
  #   assert_equal expected, client_2_response

  #   client_1.delete_environment
  #   client_2.delete_environment
  # end

  # test 'one-to-many, one thrower two catcher' do
  #   client_1 = create_client
  #   client_2 = create_client
  #   client_3 = create_client

  #   t1 = Thread.new { client_1.share("one-to-many", { :inline => "foobar" }) }
  #   t2 = Thread.new { client_2.receive("one-to-many") }
  #   sleep(2)
  #   t3 = Thread.new { client_3.receive("one-to-many") }

  #   client_3_response = t3.value
  #   client_2_response = t2.value
  #   client_1_response = t1.value

  #   assert client_1
  #   assert client_2
  #   assert client_3

  #   expected = [ { "inline" => "foobar" } ]

  #   assert_equal expected, client_1_response
  #   assert_equal expected, client_2_response
  #   assert_equal expected, client_3_response

  #   client_1.delete_environment
  #   client_2.delete_environment
  #   client_3.delete_environment
  # end

  # test 'one-to-many, two thrower one catcher' do
  #   client_1 = create_client
  #   client_2 = create_client
  #   client_3 = create_client

  #   begin
  #     t1 = threaded_share(client_1, "one-to-many", { :inline => "foobar" })
  #     sleep(1)
  #     t3 = threaded_receive(client_3, "one-to-many")
  #     sleep(1)
  #     t2 = threaded_share(client_2, "one-to-many", { :inline => "barbaz"})

  #     client_3_response = t3.value
  #     client_2_response = t2.value
  #     client_1_response = t1.value
  #   rescue => e
  #     puts e
  #   end

  #   client_1.delete_environment
  #   client_2.delete_environment
  #   client_3.delete_environment
  # end


  test 'longpolling holding get' do
    client_1 = create_client
    client_2 = create_client

    t2 = Thread.new {client_1.receive("one-to-many", :waiting => true)}
    sleep(10)
    t1 = Thread.new {client_2.share("one-to-many", { "inline" => "foobar" } )}

    client_1_response = t1.value
    client_2_response = t2.value

    expected = [{"inline" => "foobar" }]

    assert client_1_response
    assert_equal expected, client_1_response

    client_1.delete_environment
    client_2.delete_environment
  end

  # test 'longpolling twice' do
  #   client_1 = create_client
  #   client_2 = create_client

  #   t2 = Thread.new {client_1.receive("one-to-many", :waiting => true)}
  #   sleep(10)
  #   t1 = Thread.new {client_2.share("one-to-many", { "inline" => "foobar" } )}

  #   client_1_response = t1.value
  #   client_2_response = t2.value
  #   assert_equal [{"inline" => "foobar" }], client_1_response

  #   client_1.update_environment({
  #       :gps => { :latitude => 12.22, :longitude => 18.74, :accuracy => 100 }
  #   })

  #   t2 = Thread.new {client_1.receive("one-to-many", :waiting => true)}
  #   sleep(3)
  #   t1 = Thread.new {client_2.share("one-to-many", { "inline" => "barbaz" } )}

  #   client_1_response = t1.value
  #   client_2_response = t2.value
  #   assert_equal [{"inline" => "barbaz" }], client_1_response

  #   client_1.delete_environment
  #   client_2.delete_environment
  # end

  # test 'waiting clients do not intercept throws' do
  #   client_1 = create_client
  #   client_2 = create_client
  #   client_3 = create_client

  #   t1 = Thread.new {client_1.receive("one-to-many", :waiting => true)}
  #   sleep(6)
  #   t2 = Thread.new {client_2.share("one-to-many", { "inline" => "foobar" } )}
  #   sleep(1)
  #   t3 = Thread.new {client_3.receive("one-to-many")}

  #   assert_equal [{"inline" => "foobar"}], t3.value
  #   assert_equal [{"inline" => "foobar"}], t2.value
  #   assert_equal [{"inline" => "foobar"}], t1.value
  # end

  # test 'waiting clients only get the data once' do
  #   client_1 = create_client
  #   client_2 = create_client
  #   client_3 = create_client

  #   t1 = Thread.new {client_1.receive("one-to-many", :waiting => true)}
  #   sleep(1)
  #   t2 = Thread.new {client_2.share("one-to-many", { "inline" => "foobar" } )}

  #   sleep(1)
  #   assert_equal [{"inline" => "foobar"}], t1.value
  #   assert_equal [{"inline" => "foobar"}], t2.value

  #   #t3 = Thread.new {client_1.receive("one-to-many", :waiting => true)}
  #   t4 = Thread.new {client_1.receive("one-to-many")}

  #   #sleep(1)
  #   #assert_equal t3.value, nil
  # end

  # test 'waiting clients get quick delivery' do
  #   client_1 = create_client
  #   client_2 = create_client

  #   t1 = Thread.new {client_1.receive("one-to-many", :waiting => true)}
  #   sleep(6)
  #   t2 = Thread.new {client_2.share("one-to-many", { "inline" => "foobar" } )}
  #   puts "go"

  #   assert_equal [{"inline" => "foobar"}], t1.value
  #   assert_equal [{"inline" => "foobar"}], t2.value
  # end
end
