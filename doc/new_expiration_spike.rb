class PeerGroup
    
  def expired?
    expires_at < Time.now
  end
  
  def new_file_available
    expires_at = uploads.first.updated_at + 7.seconds
  end
  
end


class Distribute < PeerGroup
  
end

class Drop
  
  def new_file_available
    expires_at = uploads.max(:expires_at)
  end
  
end

class Pass
  
end


class Upload
  
  has_attachment
  
  after_update :peer_group_callback
  
  def intitialize
    @expires_at = created_at + [params[:ttl], 24.hours].min
  end
  
  def peer_group_callback
    self.peer_group.new_file_available
  end
  
end