class Event < ActiveRecord::Base

  add_geo_foo

  validates_presence_of   :latitude, :longitude

  before_create           :generate_uuid, :verify_lifetime
  before_save             :calculate_postgis_point

  belongs_to              :event_group
  has_many                :access_point_sightings
  has_one                 :upload

  accepts_nested_attributes_for :access_point_sightings

  # Class Methods

  def self.within_timeframe starting_at, ending_at
    scoped(
      :conditions => [
        "(events.starting_at, events.ending_at) OVERLAPS (timestamp ?, timestamp ?)",
        starting_at, ending_at
      ]
    )
  end

  def self.with_bssids bssids
    scoped(
      :joins => :access_point_sightings,
      :conditions => ["access_point_sightings.bssid IN (?)", bssids]
    )
  end

  def self.with_type *event_types
    if event_types.length == 1
      scoped( :conditions => { :type => event_types[0] })
    else
      scoped( :conditions => ["type IN (?)", event_types] )
    end
  end

  def self.extract_uploads events
    events.map do |event|
      {
        :uri          => event.upload.uuid,
        :content_type => event.upload.attachment.content_type,
        :filename     => event.upload.attachment.original_filename
      }
    end
  end

  # Instance Methods

  def latest_in_group
    Event.first(
      :select => "ending_at, event_group_id",
      :conditions => {:event_group_id => event_group_id},
      :order => "ending_at DESC"
    ).ending_at
  end

  def expired?
    latest_in_group < Time.now
  end

  def expires
    ( latest_in_group - Time.now ).to_i
  end

  def bssids
    access_point_sightings.all(:select => :bssid).map(&:bssid)
  end

  def linkable_type
    nil
  end

  def nearby_events custom_options = {}
    options = {
      :starting_at  => starting_at,
      :ending_at    => ending_at,
      :longitude    => longitude,
      :latitude     => latitude,
      :bssids       => bssids,
      :types        => linkable_type
    }
    
    options.merge! custom_options
    
    unless bssids.empty?
      via_accesspoints( options ) | via_locations( options )
    else
      via_locations( options )
    end
  end
  
  def via_accesspoints options
    Event .
      within_timeframe( options[:starting_at], options[:ending_at] ) .
      with_bssids( options[:bssids] ) .
      with_type( options[:types] ) .
      scoped(:conditions => ["events.id != ?", self.id])
  end
  
  def via_locations options
    Event .
      within_timeframe( options[:starting_at], options[:ending_at] ) .
      within_radius( options[:latitude], options[:longitude], 100.0 ) .
      with_type( options[:types] ) .
      scoped(:conditions => ["events.id != ?", self.id])
  end

  private

    def generate_uuid
      self.uuid = UUID.generate(:compact)
    end

    def calculate_postgis_point
      self.point = connection.execute(
        "SELECT #{GeoFoo.as_point(latitude, longitude)}"
      )[0]["st_geomfromtext"]
    end

    def initialize_upload
      upload = Upload.create :uuid => UUID.generate(:compact), :event_id => id
    end

    def verify_lifetime
      self.starting_at ||= Time.now
      self.ending_at   ||= 7.seconds.from_now
    end

    def associate_with_event_group
      linked_events = nearby_events

      if linked_events.empty?
        event_group = EventGroup.create
        event_group.events << self
      else
        linked_events.first.event_group.events << self
      end
    end
end

class Drop < Event

  after_create :initialize_upload

  def linkable_type
    "Pick"
  end

  def info
    {
      :state        => "ready",
      :message      => "like state but more verbose",
      :expires      => (Time.now - created_at),
      :upload_uri   => upload.uuid,
      :peers        => nearby_events.size,
      :status_code  => 200
    }
  end

end

class Pick < Event

  def linkable_type
    "Drop"
  end

  def info
    linked_events = nearby_events

    if linked_events.empty?
      {
        :state        => "no_content",
        :message      => "Nothing to pick up from this location",
        :status_code  => 424
      }
    else
      {
        :state        => "ready",
        :message      => "content available for download",
        :uploads      => Event.extract_uploads( linked_events ),
        :peers        => linked_events.size,
        :status_code  => 200
      }
    end
  end

end

class Throw < Event
  include Distribute
  
  after_create :initialize_upload, :associate_with_event_group

  def linkable_type
    peer
  end

  def info
    linked_events = nearby_events

    {
      :state        => "waiting",
      :message      => "waiting for other participants",
      :expires      => ( ending_at - Time.now ),
      :peers        => linked_events.size,
      :upload_uri   => upload.uuid,
      :status_code  => 202
    }
  end

end

class Catch < Event
  include Distribute

  after_create :associate_with_event_group

  def linkable_type
    seeder
  end

  def info
    linked_events = event_group.events.with_type( linkable_type )

    {
      :state        => "ready",
      :message      => "content available for download",
      :uploads      => Event.extract_uploads(linked_events),
      :peers        => linked_events.size,
      :status_code  => 202
    }
  end

end

# TODO remove Legacy

#############################
#############################
##### W A R N I N G ! #######
###### remove ahead  ########
#############################
#############################

class LegacyThrow < Event
  include Distribute
  include Legacy::Distribute
  include Legacy::General

  after_create :initialize_upload, :associate_with_event_group

  def linkable_type
    peer
  end

end

class LegacyCatch < Event
  include Distribute
  include Legacy::Distribute
  include Legacy::General

  after_create :associate_with_event_group

  def linkable_type
    seeder
  end

end

class LegacyPass < Event
  include Share
  include Legacy::General
  include Legacy::Share

  after_create :initialize_upload, :associate_with_event_group

  def linkable_type
    peer
  end

end

class LegacyReceive < Event
  include Share
  include Legacy::General
  include Legacy::Share

  after_create :associate_with_event_group

  def linkable_type
    seeder
  end
end