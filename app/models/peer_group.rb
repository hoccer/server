class PeerGroup < ActiveRecord::Base
  
  before_create :set_initial_exiration_date
  
  # Associations
  has_many :peers
  
  # Validations
  validate :no_collisions_present

  # Instance Methods
  
  def expired?
    expires_at < Time.now
  end
  
  def expire!
    self.update_attributes :expires_at => Time.now
  end
  
  def number_of_seeders
    peers.find(:all, :conditions => {:seeder => true}).count
  end
  
  def number_of_peers
    peers.find(:all, :conditions => {:seeder => false}).count
  end
  
  def collisions?
    
  end
  
  def current_state
    status[:state]
  end
  
  def upload_content_types
    seeder = peers.seeders.select {|s| s.upload && s.upload.attachment}
    seeder.map{|s| s.upload.attachment.try(:content_type)}
  end
  
  def status
    
    # can you smell the state machine ?
    
    if collisions?
      {
        :state => :collision, 
        :message => "Unfortunatly your hoc was intercepted. Try again.",
        :expires => 0, 
        :resources => [], 
        :status_code => 409
      }
    elsif !expired?
      {
        :state => :waiting,
        :message => (expires_at-Time.now).to_s,
        :expires => (expires_at-Time.now).to_i, 
        :resources => [],
        :status_code => 202
      }
    elsif expired? && 0 <  number_of_seeders && 0 == number_of_peers
      {
        :state => :no_peers,
        :message => "Nobody caught your content.",
        :expires => 0,
        :resources => [],
        :status_code => 500
      }
    elsif expired? && 0 == number_of_seeders && 0 < number_of_peers
      {
        :state => :no_seeders, 
        :message => "Nothing was thrown to you.",
        :expires => 0, 
        :resources => [],
        :status_code => 500
      }
    elsif expired? && 0 < number_of_seeders && 0 < number_of_peers
      {
        :state => :ready, 
        :message => "Downloading content",
        :expires => 0, 
        :resources => peers.map {|p| p.upload.uid if p.upload}.compact,
        :status_code => 200
      }
    end
    
  end
  
  def log_peer_group_info
    status_hash = status
    
    ">>>>>" \
    "log_format=0.1|" \
    "timestamp=#{updated_at.to_s(:db)}|" \
    "peer_group_id=#{id}|" \
    "state=#{status_hash[:state]}|" \
    "peers=#{number_of_peers}|" \
    "seeders=#{number_of_seeders}|" \
    "gesture=#{self.class.to_s}|" \
    "locations=#{peers.map {|x| x.serialize_coordinates}.join('/')}|" \
    "content_types=#{upload_content_types.join(';')}"
  end
  
  def new_file_available
    self.expires_at = Time.now + 7.seconds
    self.save
  end
  
  private
  
    def no_collisions_present
      if collisions?
        errors.add("Collision occured") 
      end
    end
    
    def set_initial_exiration_date
      if self.expires_at.blank? || self.expires_at.nil?
        self.expires_at = (Time.now + 7.seconds)
      end
    end

end

# Single Table Inheritence Classes

class Pass < PeerGroup
  def collisions?
    1 < number_of_seeders || 1 < number_of_peers
  end
end

class Distribute < PeerGroup
  def collisions?
    1 < number_of_seeders
  end
end

class Exchange < PeerGroup
  def collisions?
    
  end
end

class Drop < PeerGroup
  def collisions?
    false
  end
end