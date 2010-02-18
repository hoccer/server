class UploadsController < ApplicationController
  skip_before_filter :verify_authenticity_token 
  
  def update
    upload = Upload.find_by_uid params[:id]
    
    upload.update_attributes( params[:upload] )
    
    if upload.attachment.content_type.nil? || upload.attachment.content_type.blank? || upload.attachment.content_type =~ /^\w+\/\*$/
      content_type = MIME::Types.type_for(upload.attachment.original_filename).to_s   
      upload.update_attributes :attachment_content_type => content_type
    end
    
    render :nothing => true, :status => 200
  end
  
  def show
    
    upload = Upload.find_by_uid params[:id]
    
    if !upload.attachment_ready?
      render :nothing => true, :status => 202
    end
  
    if upload.attachment_ready?
      send_file(
        upload.attachment.path(:processed),
        :filename => upload.attachment.original_filename,
        :type => upload.attachment.content_type,
        :status => 200
      )

      upload.save
    end
  
  end
end
