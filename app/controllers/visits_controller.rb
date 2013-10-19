class VisitsController < ApplicationController

  before_filter :require_user_or_anonymous, :except => :index
  before_filter :transform_params, :only => :create
  
  skip_before_filter :redirect_from_dev
  
  respond_to :json

  def index
    render :layout => nil
  end
  
  def create
    
    @current_user = User.find_by_single_access_token(params[:user_credentials]) if params[:user_credentials]
    @current_user ||= current_user(:anonymous => true)
    
    head :status => 400 and return unless params[:article] && params[:article].is_a?(Hash) && params[:article][:url] && @current_user
    
    @article = Article.find_by_url(params[:article][:url])
    
    Abingo.identity = @current_user.abingo_identity
    bingo!("create_visit")

    if @article
      @visit = @article.visits.find_or_initialize_by_user_id(@current_user.id)
      params[:visit][:ip_address] = request.remote_ip
      @visit.update_attributes(params[:visit])
    end
  end
  
  def update
    @visit = Visit.find params[:id]
    render :status => 403 and return unless @visit.user_id == current_user(:anonymous => true).id
    @visit.update_attributes params[:visit]
    render :json => { 
      :visit => @visit
    }
  end
  
  def destroy
    @article = Article.find params[:id]
    @visit = @article.visits.where(:user_id => current_user.id).first
    # I don't think there should be an article concealment here. 
    # The user only wants to remove his traces from the article
    # current_user.concealments.create(:article => @article)
    @visit.destroy if @visit
    render :json => { :status => :ok }
  end
  
  private

  def single_access_allowed?
    true
  end
  
  def transform_params
    unless params[:article]
      params[:article] = { }
      [:url, :title, :description, :image_url].each do |param|
        params[:article][param] = params[:visit].try(:delete, param)
      end
    end
  end
  
end
