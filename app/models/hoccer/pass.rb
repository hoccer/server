module Hoccer
  module Pass

    def seeder
      "SweepOut"
    end

    def peer
      "SweepIn"
    end

    def collisions?
      (1 < number_of_peers) || (1 < number_of_seeders)
    end

    def number_of_peers
      event_group.events.with_type( peer ).count
    end

    def number_of_seeders
      event_group.events.with_type( seeder ).count
    end

    def expiration_time
      reference = Event.first(
        :select => "ending_at, created_at, event_group_id",
        :conditions => {:event_group_id => event_group_id},
        :order => "created_at ASC"
      )
      reference ? reference.ending_at : self.ending_at
    end

    def info_hash
      if event_group
        tmp_seeder        = event_group.events.with_type( seeder ).first
        event_group_size  = event_group.events.size
        upload_ready      = tmp_seeder.upload.attachment_ready? if tmp_seeder
      end

      if event_group_size == 2 && tmp_seeder && upload_ready
        event_group.events.each do |event|
          event.update_attributes(:ending_at => Time.now)
        end
      end

      result = case current_state
      when :collision
        {
          :state        => :collision,
          :message      => "Transfer was intercepted by a third person. Try again.",
          :uploads      => [],
          :expires      => 0,
          :peers        => (event_group.events - [self]).size,
          :status_code  => 409
        }

      when :waiting
        {
          :state        => :waiting,
          :message      => "linking to nearby screen",
          :expires      => expires,
          :peers        => (event_group.events - [self]).size,
          :status_code  => 202
        }

      when :no_seeders
        {
          :state        => :no_seeders,
          :message      => "Data must be dragged from an nearby screen to yours. Try again.",
          :uploads      => [],
          :expires      => 0,
          :peers        => (event_group.events - [self]).size,
          :status_code  => 410
        }

      when :no_peers
        {
          :state        => :no_peers,
          :message      => "Your data must be dragged to an nearby screen. Try again.",
          :uploads      => [],
          :expires      => 0,
          :peers        => (event_group.events - [self]).size,
          :status_code  => 410
        }

      when :ready
        {
          :state        => :ready,
          :message      => "transferring",
          :uploads      => Event.extract_uploads(event_group.events),
          :expires      => 0,
          :peers        => (event_group.events - [self]).size,
          :status_code  => 200
        }

      when :canceled
        {
          :state        => :canceled,
          :message      => "Hoc was canceled.",
          :uploads      => [],
          :expires      => 0,
          :peers        => 0,
          :status_code  => 410
        }
      end

      if upload
        result.merge({
          :upload_uri => upload.uuid
        })
      else
        result
      end

    end

  end
end
