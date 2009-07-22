class Upload < ActiveRecord::Base
  
  belongs_to        :gesture
  has_attached_file :attachment


  def attachment_ready?
    !attachment.original_filename.nil?
  end

  def within_download_limits?
    if self.download_limit.nil?
      true
    else
      download_counter < self.download_limit
    end
  end
  
  def download_limit
    if gesture.name == "pass"
      1
    else
      nil
    end
  end
end
