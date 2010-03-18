class EventsController < ApplicationController
  
  skip_before_filter :verify_authenticity_token
  
  def index
  end

  def create
    legacy_client = convert_legacy_params
    convert_bssid_params
    
    event_type  = params[:event].delete(:type)
    base        = Event.const_get(event_type.camelize)
    
    @event = base.new params[:event]

    if @event.save
      if legacy_client
        render :json => legacy_response.to_json, :status => 200
      else
        redirect_to event_path(@event.uuid), :status => 303
      end
    else
      render :nothing => true, :status => 404
    end
  end

  def show
    @event       = Event.find_by_uuid( params[:id] )
    
    # TODO remove Legacy
    event_info = legacy_info if @event.is_a? LegacyThrow
    event_info = legacy_info if @event.is_a? LegacyCatch
    
    event_info ||= resolve_resources(@event.info)
    render :json => event_info.to_json, :status => event_info[:status_code]
  end
  
  private
  
    def resolve_resources info_hash
      if info_hash[:upload_uri]
        info_hash[:upload_uri] = upload_url(info_hash[:upload_uri])
      end
      
      if uploads = info_hash[:uploads]
        uploads.each { |upload| upload[:uri] = upload_url( upload[:uri] ) }
        info_hash[:uploads] = uploads
      end
      
      info_hash
    end
  
    # Rewrites bssid array into nested attributes hash
    def convert_bssid_params
      return unless params[:event] && params[:event][:bssids]
      
      bssids = params[:event].delete(:bssids).split(",").flatten
      
      unless bssids.nil? || bssids.empty?
        access_points = {
          :access_point_sightings_attributes => bssids.map do |bssid|
            { :bssid => bssid }
          end
        }
      end
      
      params[:event].merge!(access_points) if access_points
    end
    
    # TODO Make nice legacy module
    
    def legacy_info
      info = @event.info
      uploads = info.delete(:uploads)
      info[:resources] = uploads.map {|upload| upload_url(upload)}
      info
    end
    
    def convert_legacy_params
      if legacy_params = params.delete(:peer)
        params[:event] = {
          :latitude           => legacy_params[:latitude],
          :longitude          => legacy_params[:longitude],
          :location_accuracy  => legacy_params[:accuracy],
          :type               => (legacy_params[:seeder] ? "legacy_throw" : "legacy_catch"),
          :bssids             => (legacy_params[:bssids] || [])
        }
      end
    end
    
    def legacy_response
      response = { :peer_uri => event_url(@event.uuid) }
      if @event.is_a?(LegacyThrow)
        response.merge!( :upload_uri => upload_url(@event.upload.uuid) )
      end
      
      response
    end

end
