class VisitsController < ApplicationController

  before_filter :require_user
  before_filter :transform_params, :only => :create
  
  skip_before_filter :redirect_from_dev
  
  respond_to :json
  
  def create
    
    @current_user = User.find_by_single_access_token(params[:user_credentials])
    
    head :status => 400 and return unless params[:article] && params[:article][:url]
    
    if @site = Site.find_by_full_url(params[:article][:url])
      
      @article = @site.articles.find_or_initialize_by_url(Article.cleanse_url(params[:article][:url]))
      
      if @article.new_record?
        @article.finder_id = @current_user.id
      end
      
      @article.update_attributes(params[:article])
      
      if @article.valid?
        
        @visit = @article.visits.find_or_initialize_by_user_id(current_user.id)
        
        params[:visit][:score] = 10 if params[:visit][:score].to_i > 10
        
        @visit.update_attributes(params[:visit])
        
      end
    end
    
    render :json => { 
      :article => @article.as_json(:include => [:comments]),
      :visit => @visit
    }
    
  end
  
  def destroy
    @article = Article.find params[:id]
    @visit = @article.visits.where(:user_id => current_user.id).first
    current_user.concealments.create(:article => @article)
    @visit.destroy
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
        params[:article][param] = params[:visit].delete(param)
      end
    end
  end
  
end
