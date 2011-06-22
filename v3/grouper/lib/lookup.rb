require 'mongoid'
require 'digest/sha1'

module Hoccer
  class Lookup
  include Mongoid::Document
  
    def self.lookup_uuid id 
      lookup = Lookup.where(:uuid => id).first
      if lookup.nil? 
        hash = Digest::SHA1.hexdigest(id)
        lookup = Lookup.new(:uuid => id, :hash => hash)
        lookup.save
      end
    
      lookup[:hash]
    end
  
    def self.reverse_lookup hash
      lookup = Lookup.where(:hash => hash).first
      lookup[:uuid]
    end
  end
end