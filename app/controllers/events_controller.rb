class EventsController < ApplicationController
  
  include LegacyEvents # TODO remove Legacy
  
  skip_before_filter :verify_authenticity_token
  
  def index
  end

  def create
    legacy_client = convert_legacy_params # TODO remove Legacy

    unless legacy_client
      valid_columns = Event.column_names
      valid_columns += ["bssids", "lifetime"]
      params[:event].delete_if do |k,v|
        not valid_columns.include?( k )
      end
    end
    
    convert_bssid_params
    params[:event].merge! :user_agent => request.user_agent
    
    begin
      event_type  = params[:event].delete(:type)
      base        = Event.const_get(event_type.camelize)
      @event      = base.new params[:event]
    rescue
      render :text => "Bad Event Type", :status => 400
    end

    if @event.save
      if legacy_client # TODO remove Legacy
        @event.update_attribute(:api_version, 1)
        render :json => legacy_response.to_json, :status => 200
      else
        redirect_to event_path(@event.uuid), :status => 303
      end
    else
      render :nothing => true, :status => 404
    end
  end

  def show
    @event = Event.find_by_uuid( params[:id] )
    
    if @event
      # TODO remove Legacy
      if @event.legacy?
        event_info = legacy_info
      end
      
      event_info ||= resolve_resources(@event.info)
      event_info.merge! :event_uri => event_url(@event.uuid) unless @event.legacy?
      
      render :json => event_info.to_json, :status => event_info[:status_code]
    else
      render :nothing => true, :status => 404
    end
  end
  
  def destroy
    if @event = Event.find_by_uuid( params[:id] )
      @event.update_attributes :state => "canceled"
      render :nothing => true, :status => 200
    else
      render :nothing => true, :status => 400
    end
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
            { :bssid => bssid.gsub(/\b([A-Fa-f0-9])\b/, '0\1') }
          end
        }
      end
      
      params[:event].merge!(access_points) if access_points
    end

end
