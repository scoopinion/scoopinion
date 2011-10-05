class ApplicationController < ActionController::Base
  import FacebookRegistration
    
  require 'language_guesser'

  protect_from_forgery
  
  helper_method :current_user_session, :current_user, :admin?, :chrome?, :current_user_languages, :weekend?
  
  before_filter :redirect
  
  def redirect
    
    old_hosts = [ /^huomenet.heroku.com/, /.*huome.net/, /^scoopinion.com/ ]
    
    if old_hosts.any?{ |h| h.match(request.host)}
      new_url = request.protocol + "www.scoopinion.com" + request.fullpath
      head :moved_permanently, :location => new_url    
    end    
  end
  
  def favicon
    send_file("app/assets/images/icon.png", :filename => "favicon.png")
  end

  
  private
  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return nil if params[:xxx_nologin]
    return User.find(params[:xxx_login_as]) if params[:xxx_login_as] && current_user_session && current_user_session.user.team_member?
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
  end

  def require_user
    unless current_user
      store_location
      flash[:notice] = "You must be logged in to access this page"
      redirect_to new_user_session_url
      return false
    end
  end

  def require_no_user
    if current_user
      store_location
      flash[:notice] = "You must be logged out to access this page"
      redirect_to "/articles"
      return false
    end
  end

  def store_location
    session[:return_to] = request.path
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end
  
  def admin?
    current_user.try(:team_member?)
  end
  
  def require_admin
    unless admin?
      render "application/admin"
      return false
    end
  end
  
  def chrome?
    request.user_agent.include? "Chrome"
  end
  
  def current_user_languages
    languages = (LanguageGuesser.guess(request) + [ "en" ]).uniq
    
    if current_user
      languages = (languages + current_user.feed_languages).uniq
    end
    
    languages
  end
  
  
  def weekend?
    Time.now.utc.saturday? || Time.now.utc.sunday?
  end

end
