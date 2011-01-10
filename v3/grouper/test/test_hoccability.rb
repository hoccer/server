$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), ".."))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__)))
require 'helper'

class TestHoccability < Test::Unit::TestCase

  class MockEnvironment < HashWithIndifferentAccess
    def has_wifi; self.has_key?(:wifi); end
    def has_gps; self.has_key?(:gps); end
    def has_network; self.has_key?(:network); end
    def group; [1]; end
  end

  def test_analyzing_bssids
    assert_equal ({:coordinates => Hoccability::NO_DATA,
                  :wifi => Hoccability::NO_DATA,
                  :quality => 0,
                  :devices => 1}), Hoccability::analyze(MockEnvironment.new)    
  end

  def test_judging_wifi
    assert_equal Hoccability::BAD_DATA, Hoccability::judge_wifi(["ff:ff"]), "bad bssids"
    assert_equal Hoccability::GOOD_DATA, Hoccability::judge_wifi(["00:22:3f:11:5e:5d","00:26:4d:72:cc:90"]), "good bssids"
  end

end

