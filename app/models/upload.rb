class Upload < ActiveRecord::Base
  
  belongs_to :peer
  has_attached_file( :attachment, :styles => { :processed => {} },
                     :processors => [ :vcard ])
  
  def attachment_ready?
    !attachment.original_filename.nil?
  end

end
