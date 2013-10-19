require 'base_62'
  
class ArticlesController < ApplicationController
  
  respond_to :html, :json
  
  before_filter :user_credentials_from_session
  before_filter :parse_short_id
    
  def show
    
    if params[:user_credentials] && !@noredirect
      session[:user_credentials] = params[:user_credentials]
      redirect_to(params.except(:user_credentials, :format, :short_id))
      return
    end
    
    if not params[:id].to_s["."]
      @article = Article.find_by_id(params[:id])
      @article ||= Article.find_by_url(params[:original_url]) if params[:original_url]
      if @article && @article.id.to_s != params[:id].to_s
        redirect_to short_article_url(@article.short_id) and return
      end
    else 
      @article = Article.find_by_url(params[:id])
    end
    
    unless @article
      if params[:id].to_s.index(".")
        if @site = Site.find_by_full_url(params[:id])
          @article = @site.articles.create(:url => Article.normalize_url(params[:id]))
        end
      end
    end
    
    raise ActiveRecord::RecordNotFound if ! @article && request.format.html?
    
    unless @article
      raise ActiveRecord::RecordNotFound if request.format.html?
      head :not_found and return
    end
    
    if params[:mailing_id]
      ArticleMailing.find_by_id(params[:mailing_id]).tap do |mailing|
        @mailing = mailing
        if mailing
          if ! mailing.clicked_at 
            bingo!("email_referral", :multiple_conversions => true)
            
            if !current_user(:anonymous => true)
              Visit.find_or_create_by_article_id_and_user_id(@article.id, mailing.user.id) do |v|
                v.referrer ||= "https://www.scoopinion.com/email"
              end
            end
            
          end
          mailing.clicked!
        end
      end
    end
    
    if params[:source] && current_user(:anonymous => true)
      Visit.find_or_create_by_article_id_and_user_id(@article.id, current_user(:anonymous => true).id) do |v|
        v.referrer ||= "https://www.scoopinion.com/#{params[:source]}"
      end
      bingo!("referral")
      bingo!("issue_referral", :multiple_conversions => true) if params[:source] == "issue"
    end
    
    redirect = false
    redirect = true if extension? && old_user?
    redirect = false if params[:source] == "email"
    redirect = true if mobile_device?
    redirect = true if params[:source] == "chrome"
    redirect = true if (current_user && current_user.id == 365098) || (@mailing && @mailing.user_id == 365098) #XXX
    redirect = false if params[:force_iframe]
        
    respond_with(@article) do |format|
      format.json
      format.html do
        if redirect
          redirect_to @article.remote_url and return
        else
          render :layout => "iframe"
        end
      end

    end
  end
  
  private
  
  def old_user?
    current_user && current_user.created_at < Time.utc(2012, 10, 14)
  end
  
  def parse_short_id
    if params[:short_id]
      params[:id] = Base62.to_i(params[:short_id].reverse)
      params[:format] = "html"
    end
  end
  
  def set_abingo_identity
    super
    if params[:mailing_id] && params[:id] != "1009855"
      mailing = ArticleMailing.find(params[:mailing_id])
      if mailing.try(:user).try(:abingo_identity)
        Abingo.identity = mailing.user.abingo_identity
      end
    end
  end
  
  def single_access_allowed?
    true
  end
  
  def user_credentials_from_session
    if !params[:user_credentials]
      params[:user_credentials] = session[:user_credentials]
      @noredirect = true
    end
  end
  
  def current_user(options={ })
    if session[:user_credentials]
      return super if @single_access_current_user == false
      @single_access_current_user ||= User.find_by_single_access_token(session[:user_credentials])
      return @single_access_current_user if @single_access_current_user
      @single_access_current_user = false
    end
    super
  end

  
end

