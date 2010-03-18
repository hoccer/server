module LegacyEvents
  
  private
  
  def legacy_info
    info = @event.info
    info[:resources] = info[:resources].map {|upload| upload_url(upload)}
    info
  end
  
  def convert_legacy_params
    
    if legacy_params = params.delete(:peer)
    
      params[:event] = {
        :latitude           => legacy_params[:latitude],
        :longitude          => legacy_params[:longitude],
        :location_accuracy  => legacy_params[:accuracy],
        :type               => event_type_from( legacy_params ),
        :bssids             => (legacy_params[:bssids] || [])
      }
    end
  end
  
  def event_type_from legacy_params
    seeder_param  = legacy_params[:seeder]
    gesture_param = legacy_params[:gesture]
    
    if seeder_param.is_a? String
      if (seeder_param == "0" || seeder_param == "false")
        seeder = false
      else
        seeder = true
      end
    else
      seeder = seeder_param
    end
    
    if gesture_param == "pass" && seeder
      "legacy_pass"
    elsif gesture_param == "pass" && !seeder
      "legacy_receive"
    elsif gesture_param == "distribute" && seeder
      "legacy_throw"
    elsif gesture_param == "distribute" && !seeder
      "legacy_catch"
    end
  end
  
  def legacy_response
    response = { :peer_uri => event_url(@event.uuid) }
    if @event.is_a?(LegacyThrow) || @event.is_a?(LegacyPass)
      response.merge!( :upload_uri => upload_url(@event.upload.uuid) )
    end
    
    response
  end
end