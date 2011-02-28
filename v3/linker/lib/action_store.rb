
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
    send_no_content action unless action.nil?
    self[uuid] = nil
  end

  def conflict uuid
    action = self[uuid]
    if action && action[:request]
      if (jsonp = action[:jsonp_method])
        action[:request].status 200
        action[:request].body { "#{jsonp}(#{ {"message" => "conflict"}.to_json })" }
      else
        action[:request].status 409
        action[:request].body { {"message" => "conflict"}.to_json }
      end
    end
    self[uuid] = nil
  end

  def send uuid, content
    puts "sending data #{content.inspect} to #{uuid}"

    action = self[uuid]
    if action && action[:request]
      action[:request].status 200
      if (jsonp = action[:jsonp_method])
        action[:request].body { "#{jsonp}(#{content.to_json})" }
      else
        action[:request].body content.to_json
      end
    end
    self[uuid] = nil
  end

  def actions_in_group group, mode
    actions = group.inject([]) do |result, environment|
      action = self[ environment["client_uuid"] ] rescue nil
      result << action unless action.nil?
      result
    end

    actions.select {|action| action[:mode] == mode}
  end

  private
  def send_no_content action
    puts "timeout for #{action[:uuid]}"

    if action && action[:request]
      request = action[:request]
      if (jsonp = action[:jsonp_method])
        request.status 200
        action[:request].body { "#{jsonp}(#{ {"message" => "timeout"}.to_json})" }
      else
        request.status 204
        request.body { {"message" => "timeout"}.to_json }
      end

    end
  end
end
