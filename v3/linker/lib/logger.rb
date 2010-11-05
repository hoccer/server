class Logger
  def self.successful_transfer share_id, receive_id, mode
    self.write({ :share_id => share_id, :receive_id => receive_id,
            :mode => mode, :type => 'successful_transfer' })
  end

  def self.failed_share client_id, mode
    write( { :type => "failed_share", :share_id => client_id, :mode => mode } )
  end

  def self.failed_receive client_id, mode
    write( { :type => "failed_receive", :receive_id => client_id, :mode => mode } )
  end

  def self.successful_actions actions
    sender, receiver = actions.partition { |action| action[:type] == :sender }
    sender_id = sender.map { |s| s[:uuid] }
    receiver_id = receiver.map { |r| r[:uuid] }

    successful_transfer sender_id, receiver_id, actions.first[:mode]
  end

  def self.failed_action action
    if action[:type] == :sender
      failed_share action[:uuid], action[:mode]
    else
      failed_receive action[:uuid], action[:mode]
    end
  end

  def self.write doc
    doc[:timestamp] = Time.now
    db.collection('linccer_stats').insert(doc)
  end

  def self.db
    @@db ||= EM::Mongo::Connection.new.db('hoccer_development')
  end
end
