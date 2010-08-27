class Upload < ActiveRecord::Base

  belongs_to :peer
  belongs_to :event

  has_attached_file( :attachment, :styles => { :processed => {} },
                     :processors => [ :vcard ])

  attr_accessor :transfered_content_type

  def attachment_ready?
    !attachment.original_filename.nil?
  end

end
