
class ActionStore < Hash
  
  def hold_action_for_seconds action, seconds 
    uuid = action[:uuid]
    self[uuid] = action
    
    EM::Timer.new(seconds) do
      invalidate uuid
    end
  end
  
  def invalidate uuid 
    action = self[uuid]
    send_no_content action
    self[uuid] = nil
  end
  
  def actions_in_group group, mode 
    actions = group.inject([]) do |result, environment|
      action = self[ environment["client_uuid"] ]
      result << action unless action.nil?
      result
    end
    
    actions.select {|action| action[:mode] == mode}
  end
  
  private
  def send_no_content action 
    if action && action[:request]
      Logger.failed_action action
      
      request = action[:request]
      request.status 204
      request.body { {"message" => "timeout"}.to_json }
    end
  end 
end
