class PeerGroup < ActiveRecord::Base
  has_many :peers
  
  validate :no_collisions_present

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
  
  def status
    
    # can you smell the state machine ?
    
    if collisions?
      {
        :state => :collision, 
        :expires => 0, 
        :resources => [], 
        :status_code => 409
      }
    elsif !expired?
      {
        :state => :waiting,
        :expires => (expires_at-Time.now).to_i, 
        :resources => [],
        :status_code => 202
      }
    elsif expired? && 0 <  number_of_seeders && 0 == number_of_peers
      {
        :state => :no_peers,
        :expires => 0,
        :resources => [],
        :status_code => 500
      }
    elsif expired? && 0 == number_of_seeders && 0 <  number_of_peers
      {
        :state => :no_seeders, 
        :expires => 0, 
        :resources => [],
        :status_code => 500
      }
    elsif expired? && 0 <  number_of_seeders && 0 <  number_of_peers
      {
        :state => :ready, 
        :expires => 0, 
        :resources => peers.map {|p| p.upload.uid if p.upload}.compact,
        :status_code => 200
      }
    end
    
  end
  
  private
  
    def no_collisions_present
      if collisions?
        errors.add("Collision occured") 
      end
    end

end


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