class PagesController < ApplicationController

  before_filter :require_user, :if => lambda { params[:page] == "extension" }

  def show
    render params[:page]
  end

end

