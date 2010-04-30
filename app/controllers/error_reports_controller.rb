class ErrorReportsController < ApplicationController
  
  def create
    error_report = ErrorReport.new params[:error_report]
    
    if error_report.save
      render :nothing => true, :status => 200
    else
      render :nothing => true, :status => 400
    end
  end
  
end
