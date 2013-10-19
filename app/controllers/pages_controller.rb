class PagesController < ApplicationController
  
  before_filter :redirect
  before_filter :require_user, :if => lambda { %w(extension alldone).include? params[:page] }
  before_filter :require_admin, :if => lambda { %(cohort_stats).include? params[:page] }
  before_filter :require_page_file
  layout proc{|c| c.request.xhr? ? false : "application" }
    
  def show    
    @subpage = "pages/#{params[:page]}/#{params[:subpage]}" if params[:subpage]
    @user_session = UserSession.new if params[:page] == "welcome"
    render params[:page]
  end
  
  def require_page_file
    raise ActiveRecord::RecordNotFound unless FileTest.exist?("app/views/pages/#{params[:page]}.html.haml")
  end
  
  private
  
  def redirect
    redirect_to page_url("about") and return if params[:page] == "contact"
    redirect_to page_url("extension") and return if params[:page] == "download"
  end

  
  def single_access_allowed?
    params[:page] == "extension"
  end
  
end

