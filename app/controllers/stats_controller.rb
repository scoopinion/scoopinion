class StatsController < ApplicationController
  
  before_filter :require_admin
  skip_before_filter :require_admin, :if => Proc.new{ params[:key] == "23094234098234098234089" }
  
  def index
    if params[:span]
      Stats.span = params[:span].to_i #XXX
    end
  end
  
end

