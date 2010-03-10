class Event < ActiveRecord::Base
  
  add_geo_foo
  
  validates_presence_of :latitude, :longitude
  
  before_save :calculate_postgis_point
  
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