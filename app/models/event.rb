class Event < ActiveRecord::Base
  
  add_geo_foo
  
  validates_presence_of :latitude, :longitude
  
  before_save :calculate_postgis_point
  
  # Class Methods
  
  def self.within_timeframe starting_at, ending_at
    scoped(
      :conditions => [
        "(events.starting_at, events.ending_at) OVERLAPS (timestamp ?, timestamp ?)",
        starting_at, ending_at
      ]
    )
  end
  
  # Instance Methods
  
  def nearby_events
    Event.within_timeframe(
      starting_at, ending_at
    ).within_radius(
      latitude, longitude, 100.0
    ).scoped(:conditions => ["id != ?", self.id])
  end
  
  
  private
  
    def calculate_postgis_point
      self.point = connection.execute(
        "SELECT #{GeoFoo::Core.as_point(latitude, longitude)}"
      )[0]["st_geomfromtext"]
    end
end

class Drop < Event
  
end

class Pick < Event
  
end