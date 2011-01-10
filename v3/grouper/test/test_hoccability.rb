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
    assert_equal Hoccability::WRONG_DATA, Hoccability::judge_wifi({:bssids => ["ff:ff"]}), "bad bssids"
    wifi = {:bssids => ["00:22:3f:11:5e:5d","00:26:4d:72:cc:90"]}
    assert_equal Hoccability::NO_TIMESTAMP, Hoccability::judge_wifi(wifi), "no timestamp"
    wifi[:timestamp] = Time.now.to_i - 2.minutes
    assert_equal Hoccability::OLD_DATA, Hoccability::judge_wifi(wifi), "old bssids"
    wifi[:timestamp] = Time.now.to_i
    assert_equal Hoccability::GOOD_DATA, Hoccability::judge_wifi(wifi), "good bssids"  end

  def test_judging_coordinates
    judge = lambda {|gps| Hoccability::judge_coordinates gps}

    gps = {:longitude => 13.33, :latitude => 52.33, :accuracy => 100}
    assert_equal Hoccability::NO_TIMESTAMP, judge.call(gps), "no timestamp"
    gps[:timestamp] = Time.now.to_i - 2.minutes
    assert_equal Hoccability::OLD_DATA, judge.call(gps), "old fix"
    gps[:timestamp] = Time.now.to_i
    assert_equal Hoccability::GOOD_DATA, judge.call(gps), "good fix"
    gps[:accuracy] = 19
    assert_equal Hoccability::EXACT_DATA, judge.call(gps), "exact fix"
    gps[:accuracy] = 350
    assert_equal Hoccability::IMPRECISE_DATA, judge.call(gps), "inaccurate fix"
  end

end

