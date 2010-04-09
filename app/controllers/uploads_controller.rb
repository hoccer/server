class UploadsController < ApplicationController

  skip_before_filter :verify_authenticity_token

  def update
    upload = Upload.find_by_uuid params[:id]
    upload.update_attributes( params[:upload] )

    content_type = MIME::Types.type_for(upload.attachment.original_filename).to_s
    
    unless content_type.blank? || content_type == upload.attachment.content_type
      upload.update_attributes :attachment_content_type => content_type
    end

    render :nothing => true, :status => 200
  end

  def show

    upload = Upload.find_by_uuid params[:id]
    
    if upload.nil?
      render :nothing => true, :status => 404
    end

    unless upload.nil? && upload.attachment_ready?
      render :nothing => true, :status => 202
    end

    if upload && upload.attachment_ready?
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
