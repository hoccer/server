class UploadsController < ApplicationController
  
  def create
    
    gesture = Gesture.find(params[:gesture_id])
    
    if gesture.uploads.create params[:upload]
      render :nothing => true, :status => 200
    else
      render :nothing => true, :status => 500
    end
  end
  
  def update
    upload = Upload.find_by_checksum params[:id]
    upload.update_attributes( params[:upload] )
    render :nothing => true, :status => 200
  end

  def show
    
    upload = Upload.find_by_checksum params[:id]
    
    if !upload.attachment_ready?
      render :nothing => true, :status => 204
    end

    if upload.attachment_ready? && !upload.within_download_limits?
      render :nothing => true, :status => 403
    end

    if upload.attachment_ready? && upload.within_download_limits?
      send_file(
        upload.attachment.path,
        :filename => upload.attachment.original_filename,
        :type => upload.attachment.content_type,
        :status => 200
      )
      
      upload.download_counter += 1
      upload.save
    end

  end
end
