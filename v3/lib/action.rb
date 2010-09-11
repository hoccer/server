module Hoccer

  class ActionStore < Hash

    VALID_ACTIONS = [:pass, :distribute]

    def initialize client_uuid
      @client_uuid = client_uuid
    end

    def [] key
      super key.to_sym
    end

    def []= key, value
      action_name = key.to_sym

      unless VALID_ACTIONS.include? action_name
        raise ArgumentError, "Invalid Action Name"
      end

      unless value.is_a? Hash
        raise ArgumentError, "Action value must be Hash"
      end

      value.merge!(
        :name         => action_name,
        :client_uuid  => @client_uuid,
        :created_at   => Time.now,
        :uuid         => UUID.generate(:compact)
      )

      if old_action = self[action_name]
        #TODO Put old action into persistant store for looking it up later
      end

      super action_name, value
    end
  end

end
