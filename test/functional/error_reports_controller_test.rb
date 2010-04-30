require 'test_helper'

class ErrorReportsControllerTest < ActionController::TestCase

  test "reporting an error" do
    assert_difference "ErrorReport.count", +1 do
      post :create, :error_report => { :body => "Does not work!" }
    end
    
    assert_equal "Does not work!", ErrorReport.last.body
  end

end
