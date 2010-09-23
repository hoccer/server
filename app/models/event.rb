class Event < ActiveRecord::Base
  GuaranteedRadius = 100
  MaxUncertaintiy  = 5050

  add_geo_foo

  #validates_presence_of   :latitude, :longitude

  before_create           :generate_uuid, :verify_lifetime, :set_api_version
  before_save             :calculate_postgis_point

  belongs_to              :event_group
  has_many                :access_point_sightings
  has_one                 :upload, :dependent => :destroy

  accepts_nested_attributes_for :access_point_sightings

  attr_protected          :api_version

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
    events_with_upload = events.select do |event|
      event.upload && event.upload.uuid && !event.upload.attachment_file_name.nil?
    end

    events_with_upload.map do |event|
      {
        :uri          => event.upload.uuid,
        :content_type => event.upload.attachment.content_type,
        :filename     => event.upload.attachment.original_filename,
        :latitude     => event.latitude,
        :longitude    => event.longitude
      }
    end
  end

  def self.somewhere_near lat, lon, accuracy
    boxSize = bbox_size lat, 1.2 * MaxUncertaintiy # paranoia factor 1.2
    point = GeoFoo.as_point(lat, lon)
    scoped(
      :conditions => [
        "ST_DWithin(point, #{point}, #{boxSize}) AND "\
        "ST_Distance_Sphere(point, #{point}) <= ? + least(?, 2*(location_accuracy + ?))",
        GuaranteedRadius,
        MaxUncertaintiy,
        accuracy
      ]
    )
  end

  # Instance Methods

  # TODO FIXME CONSOLIDATE
  # def expiration_time
  #   Event.first(
  #     :select => "ending_at, event_group_id",
  #     :conditions => {:event_group_id => event_group_id},
  #     :order => "ending_at DESC"
  #   ).ending_at
  # end

  def expired?
    expiration_time < Time.now
  end

  def expires
    ( expiration_time - Time.now ).ceil
  end

  def bssids
    access_point_sightings.all(:select => :bssid).map(&:bssid)
  end

  def linkable_type
    nil
  end

  def seeder?
    seeder == type
  end

  def peer?
    peer == type
  end

  def legacy?
    api_version == 1
  end

  def nearby_events custom_options = {}
    options = {
      :starting_at  => starting_at,
      :ending_at    => ending_at,
      :longitude    => longitude,
      :latitude     => latitude,
      :bssids       => bssids,
      :types        => linkable_type,
      :accuracy     => location_accuracy
    }

    options.merge! custom_options

    if latitude.nil? and longitude.nil?
      via_accesspoints( options )
    elsif bssids.empty?
      via_locations( options )
    else
      via_accesspoints( options ) | via_locations( options )
    end
  end

  def via_accesspoints options
    results = Event .
      within_timeframe( options[:starting_at], options[:ending_at] ) .
      with_bssids( options[:bssids] ) .
      with_type( options[:types] ) .
      scoped(:conditions => ["events.id != ?", self.id])

    self.update_attribute(:pairing_mode, 0b10) if 0 < results.size
    results
  end

  def via_locations options
    results = Event .
      within_timeframe( options[:starting_at], options[:ending_at] ) .
      somewhere_near( options[:latitude], options[:longitude], options[:accuracy] ) .
      with_type( options[:types] ) .
      scoped(:conditions => ["events.id != ?", self.id])

    update_pairing_mode(0b1) if 0 < results.size
    results
  end

  def update_pairing_mode bits
    self.update_attribute( :pairing_mode, (pairing_mode | bits) )
  end

  def current_state
    return state.to_sym unless %w(waiting error).include?( state )

    new_state = if collisions?
      :collision
    elsif !expired?
      :waiting
    elsif expired? && 0 <  number_of_seeders && 0 == number_of_peers
      :no_peers
    elsif expired? && 0 == number_of_seeders && 0 < number_of_peers
      :no_seeders
    elsif expired? && 0 < number_of_seeders && 0 < number_of_peers
      :ready
    else
      :error
    end

    if new_state != state
      Event.update_all(
        "state = '#{new_state.to_s}'",
        ["event_group_id = ?", event_group_id]
      )
    end

    new_state
  end

  def info
    extend Hoccer::Legacy if legacy?

    # nil, [] or [e1,e2]
    neighbors = (event_group.events - [self]) if event_group
    neighbors ||= []

    return info_hash if (neighbors.size > 0)

    possible_neighbors = nearby_events(:types => [peer, seeder])

    if neighbors.empty? && possible_neighbors.empty?
      logger.info "GROUP: Really, there is nobody around"
    elsif neighbors.empty? && !possible_neighbors.empty?
      logger.info "GROUP: Empty group but new neighbors around. REGROUP!"

      begin
        Event.transaction do
          new_group = EventGroup.create!

          logger.info "Trying to aquire Locks for Events"
          puts "Trying to aquire Locks for Events"

          events_for_group = Event.find(
            ( possible_neighbors + [self] ).map(&:id),
            :lock => 'FOR UPDATE NOWAIT'
          )

          logger.info "Successfully aquired Locks for Events"
          puts "Successfully aquired Locks for Events"

          events_for_group.each do |event|
            event.update_attributes(:event_group_id => new_group.id)
            logger.info "GROUP: Updated event with id #{event.id}"
            puts "GROUP: Updated event with id #{event.id}"
          end

          logger.info "Updated Events"
          puts "Updated Events"

          logger.info "GROUP: #{new_group.events.map(&:id).inspect}"
          puts "GROUP: #{new_group.events.map(&:id).inspect}"

          self.reload
        end
      rescue ActiveRecord::StatementInvalid => ex
        logger.info "GROUP: Could not aqcuire lock"
      rescue => ex
        logger.warn "!!!!!!!!!!!!! #{ex.inspect}"
      end
    else
      logger.warn "!!! You really shouldn't be here"
    end

    info_hash
  end


  private

    def generate_uuid
      self.uuid = UUID.generate(:compact)
    end

    def calculate_postgis_point
      if latitude and longitude
        self.point = connection.execute(
          "SELECT #{GeoFoo.as_point(latitude, longitude)}"
        )[0]["st_geomfromtext"]
      end
    end

    def initialize_upload
      upload = Upload.create :uuid => UUID.generate(:compact), :event_id => id
    end

    def set_api_version
      self.api_version ||= 2
    end

    # TODO Revisit for cleaner prettier implementation -> lifetime etc
    def verify_lifetime
      self.starting_at ||= Time.now

      if respond_to?(:lifetime) && lifetime
        self.ending_at = starting_at + lifetime.to_i
      else
        self.ending_at ||= 7.seconds.from_now
      end
    end

    def associate_with_event_group
      linked_events = nearby_events( :types => [seeder, peer] )
      linked_events = linked_events.select(&:event_group)

      if linked_events.empty?
        event_group = EventGroup.create
      else
        event_group = linked_events.first.event_group
      end

      event_group.events << self
    end
end

class Drop < Event
  include Hoccer::Cache

  after_create    :initialize_upload

  attr_accessor   :lifetime

  def linkable_type
    peer
  end

end

class Pick < Event
  include Hoccer::Cache

  def linkable_type
    seeder
  end

end

class Throw < Event
  include Hoccer::Distribute

  after_create :initialize_upload, :associate_with_event_group

  def linkable_type
    peer
  end

end

class Catch < Event
  include Hoccer::Distribute

  after_create :associate_with_event_group

  def linkable_type
    seeder
  end

end

class SweepOut < Event
  include Hoccer::Pass

  after_create :initialize_upload, :associate_with_event_group

  def linkable_type
    peer
  end

end

class SweepIn < Event
  include Hoccer::Pass

  after_create :associate_with_event_group

  def linkable_type
    seeder
  end

end
