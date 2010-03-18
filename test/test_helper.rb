ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually 
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
  
  def create_event_with_times starting_at, ending_at, base = Event
    base.create( 
      :longitude    => 52.0, 
      :latitude     => 13.0,
      :starting_at  => starting_at,
      :ending_at    => ending_at
    )
  end
  
  def create_event_with_locations latitude, longitude, bssids = [], base = Event
    base.create( 
      :longitude    => latitude, 
      :latitude     => longitude,
      :starting_at  => Time.now,
      :ending_at    => Time.now+7.seconds,
      :access_point_sightings_attributes => bssids
    )
  end
  
  def expire event_group
    event_group.events.each do |event|
      event.update_attributes(
        :starting_at  => event.starting_at - 7.seconds,
        :ending_at    => event.ending_at - 7.seconds
      )
    end
  end
  
end
