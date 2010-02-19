class Upload < ActiveRecord::Base
  
  belongs_to :peer
  has_attached_file( :attachment, :styles => { :processed => {} },
                     :processors => [ :vcard ])
  
  attr_accessor :transfered_content_type
  
  after_update :peer_group_callback
  
  
  def attachment_ready?
    !attachment.original_filename.nil?
  end
  
  private
    def peer_group_callback
      self.peer.peer_group.new_file_available if self.peer
    end

end
