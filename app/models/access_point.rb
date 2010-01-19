class AccessPoint < ActiveRecord::Base
  
  has_and_belongs_to_many :peers
  
  named_scope :recent, lambda { {:conditions => ["created_at > ?", (10.seconds.ago)]}}
  
end
