module Hoccer
  module Distribute

    def seeder
      "Throw"
    end

    def peer
      "Catch"
    end

    def collisions?
      1 < number_of_seeders
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
      tmp_state     = current_state

      if event_group
        tmp_seeder    = event_group.events.with_type( seeder ).first
        upload_ready  = tmp_seeder.upload.attachment_ready? if tmp_seeder
      end

      if tmp_state == :waiting && peer? && tmp_seeder && upload_ready
        tmp_state = :ready
      end

      result = case tmp_state

      when :waiting
        {
          :state        => "waiting",
          :message      => "linking to nearby participants",
          :expires      => expires,
          :peers        => (event_group.events - [self]).size,
          :status_code  => 202
        }

      when :collision
        {
          :state        => "collision",
          :message      => "Transfer was intercepted by a second thrower. Try again.",
          :expires      => 0,
          :peers        => (event_group.events - [self]).size,
          :status_code  => 409
        }

      when :no_peers
        {
          :state        => "no_peers",
          :message      => "No one nearby catched your content. Try again.",
          :expires      => 0,
          :peers        => (event_group.events - [self]).size,
          :status_code  => 410
        }

      when :no_seeders
        {
          :state        => "no_seeders",
          :message      => "For catching, a nearby person needs to throw data to you.",
          :expires      => 0,
          :peers        => (event_group.events - [self]).size,
          :status_code  => 410
        }

      when :ready
        {
          :state        => "ready",
          :message      => "transferring",
          :expires      => 0,
          :peers        => (event_group.events - [self]).size,
          :uploads      => Event.extract_uploads(event_group.events),
          :status_code  => 200
        }

      when :canceled
        {
          :state        => :canceled,
          :message      => "Hoc was canceled",
          :uploads      => [],
          :expires      => 0,
          :peers        => 0,
          :status_code  => 410
        }

      when :error
        {
          :state        => :error,
          :message      => "An error occurred",
          :uploads      => [],
          :expires      => 0,
          :peers        => 0,
          :status_code  => 400
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
