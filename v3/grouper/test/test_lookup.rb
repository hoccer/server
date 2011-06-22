$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), ".."))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__)))
require 'helper'
require 'uuid'

class TestLookup < Test::Unit::TestCase
  
  test 'lookup creates hash' do
    uuid = UUID.generate
    
    hash = Lookup.lookup_uuid uuid
    assert hash, "should always return a id"
  end
  
  test 'lookup twice result in same uuid' do
    uuid = UUID.generate
    
    hash1 = Lookup.lookup_uuid uuid
    hash2 = Lookup.lookup_uuid uuid
    assert_equal hash1, hash2
  end
  
  test 'reverse lookup' do
    uuid = UUID.generate
    
    hash         = Lookup.lookup_uuid uuid
    reverse_uuid = Lookup.reverse_lookup hash
    
    assert_equal uuid, reverse_uuid
  end

end