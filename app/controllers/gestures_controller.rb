require 'sha1'


class GesturesController < ApplicationController
  
  def create
    host = "#{request.protocol}#{request.env["HTTP_HOST"]}"
    
    location = Location.create_from(params[:location_id])
    gesture =  Gesture.create!(params[:gesture])
    location.gestures << gesture
        
    sha = SHA1.new( 
      location_gesture_url(
        :id   => gesture.id, 
        :location_id  => location.serialized_coordinates
      ) + Time.now.to_s
    ).to_s
    
    upload = Upload.create(:checksum => sha)
    gesture.upload = upload
    upload.save

    response = {:uri => "#{host}/uploads/#{sha}"}
    
    render :json => response.to_json
  end
    
end
