$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), ".."))
require 'helper'
require 'test_client'

class ExhibitTest < Test::Unit::TestCase

  def setup
    @client = TestClient.new
  end

  def random_location
    operand = (rand(2) % 2) == 0 ? +1 : -1

    {
      :gps => {
        :longitude => (13.414993 + (rand/50 * operand)),
        :latitude  => (52.520817 + (rand/50 * operand)),
        :accuracy  => 100.0
      }
    }
  end

  test "dropping data" do
    response = @client.drop(
      :params => { :note => new_message },
      :environment => random_location
    )
    assert_equal "200", response.header.code
  end

end
