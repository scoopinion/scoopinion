class ApplicationController < ActionController::Base
  require 'language_guesser'

  protect_from_forgery
  
  helper_method :current_user_session, :current_user, :admin?, :chrome?, :current_user_languages, :weekend?, :firefox?, :current_or_anonymous_user, :extension?, :invite, :offline?
  
  before_filter :redirect
  
  after_filter :collect_user_analytics_data
  
  before_filter :init
  
  before_filter :record_extension
  
  before_filter :set_locale
  
  before_filter :set_abingo_identity
  
  before_filter :track_email_click
  
  def track_email_click
    if params[:conv]
      conversion, user_id = params[:conv].split("-")
      return unless conversion && user_id
      user = User.find_by_id(user_id)
      return unless user
      old_identity = Abingo.identity
      Abingo.identity = user.init_abingo
      bingo!("link_" + conversion)
      Abingo.identity = old_identity
    end
    return true
  end
  
  def offline?
    return false unless Rails.env.development?
    session[:offline] = true if params[:offline]
    session[:offline] = false if params[:offline] == "false"
    return session[:offline]
  end
  
  def set_abingo_identity
    if request.local? && params.key?(:bingo)
      Abingo.identity = rand(10 ** 10).to_i.to_s
    elsif user = current_user(anonymous: true)
      unless user.abingo_identity
        user.update_attributes(:abingo_identity => (session[:abingo_identity] || rand(10 ** 10).to_i.to_s))
      end
      Abingo.identity = user.abingo_identity
    else
      session[:abingo_identity] ||= rand(10 ** 10).to_i.to_s
      Abingo.identity = session[:abingo_identity]
    end

    if (request.user_agent =~ /\b(Baidu|Gigabot|Googlebot|libwww-perl|lwp-trivial|msnbot|SiteUptime|Slurp|WordPress|ZIBB|ZyBorg|NewRelicPinger)\b/i)
      Abingo.identity = "robot"
    end
  end
  
  def set_locale
    locale = "en"

    if current_user and current_user.site_language
      locale = current_user.site_language
    else
      accepted_languages = LanguageGuesser.accepted_languages(request)
      locale = "fi" if accepted_languages.include? "fi"
    end
    
    locale = session[:locale] if session[:locale]
    
    locale = params[:locale] if params[:locale] && I18n.available_locales.include?(params[:locale].to_sym)
    session[:locale] = params[:locale] if params[:locale]
    
    I18n.locale= locale
  end
  
  def collect_user_analytics_data
    session[:referrer] ||= request.referrer || ""
    session[:entry_point] ||= request.url
    session[:invitation_id] ||= params[:invitation_id]
    if current_user(:anonymous => true) && current_user(:anonymous => true).anonymous?
      current_user(:anonymous => true).update_attributes(:user_analytics_item_attributes => { 
                                                           :referrer => session[:referrer], 
                                                           :entry_point => session[:entry_point],
                                                           :invitation_id => session[:invitation_id],
                                                           :user_agent => request.user_agent
                                                         })
      current_user(:anonymous => true).user_analytics_item.save
    end
  end
  
  def init
    @start_time = Time.now
  end
  
  def record_extension
    if current_user && extension? && !current_user.extension_installed_at
      current_user.update_attributes(:extension_installed_at => Time.now)
      Abingo.identity = current_user.abingo_identity
      bingo!("install_addon")
    end
  end
  
  def redirect
    
    secondary_hosts = 
      [ 
       /^huomenet.heroku.com$/, 
       /.*huome.net$/, 
       /^scoopinion.com$/, 
       /^scpn.in$/, 
       /.*scoopinion.fi$/, 
       /.*skuuppari.com$/, 
       /.*skuuppari.fi$/,
       /^api.scoopinion.com$/
      ]
    
    new_params = { }
    
    current_host = request.host.gsub(".local", "")
    
    if /.*.fi/.match(current_host)
      new_params[:locale] = "fi"
    end
    
    if secondary_hosts.any?{ |h| h.match(current_host) }
      new_host = "www.scoopinion.com"
      new_host = "www.scoopinion.com.local:3000" if Rails.env.development?
      
      new_url = request.protocol + new_host + request.path 
      new_params = request.GET.merge(new_params)
      new_url = new_url + "?" + new_params.to_query if new_params.any?
      
      head :moved_permanently, :location => new_url and return
    end
    
    if current_host =~ /^scoopinion.heroku.com/ && request.protocol == "http://" && !firefox?
      render :inline => 'Please click <a href="https://www.scoopinion.com" target="_top">here</a> 
      if you are not automatically redirected.
      <script>top.location.href="https://www.scoopinion.com";</script>'
    end
  end
  
  def favicon
    response.headers['Cache-Control'] = 'public, max-age=86400'
    send_file("app/assets/images/icon.png", :filename => "favicon.ico")
  end

  def profile_access?(user)
    return true if ENV["PROFILE_OUT"] != nil
    user_id = user ? user.id : nil
    beta_group?(user_id)
  end

  private

  def beta_group?(id)
    User::TEAM_IDS.include?(id) || JsonCache.read("profile_page_beta_ids").try(:include?, id)
  end

  def mobile_device?
    if session[:mobile_param]
      session[:mobile_param] == "1"
    else
      request.user_agent =~ /android|blackberry|iPhone|Mobile|webOS|Maemo|Windows Phone/i && !(request.user_agent =~ /iPad/i)
    end
  end
  helper_method :mobile_device?

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user(options={ })
    return current_or_anonymous_user if options[:anonymous]    
    return nil if params[:xxx_nologin]
    return nil if @current_user && @current_user.anonymous?
    return nil if current_user_session && !current_user_session.user
    return nil if current_user_session && current_user_session.user.anonymous?
    return User.find(params[:xxx_login_as]) if params[:xxx_login_as] && current_user_session && current_user_session.user.team_member?
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
  end
  
  def current_or_anonymous_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user    
  end
  
  def require_user_or_create_anonymous
    unless current_or_anonymous_user
      if session[:abingo_identity]
        abingo_identity = session[:abingo_identity]
      else
        abingo_identity = rand(10 ** 10).to_i.to_s
      end
      @current_user = User.create_anonymous(:abingo_identity => abingo_identity)
      logger.debug @current_user
      logger.debug @current_user.errors.full_messages
      @current_user_session = UserSession.new(:user => @current_user, :remember_me => true)
      @current_user_session.save
    end
  end
  
  def require_user(options = { :anonymous => false })
    unless current_user(options)
      store_location
      flash[:notice] = "You must be logged in to access this page"
      respond_to do |format|
        format.html { redirect_to new_user_session_url(:next => request.path) and return false }
        format.json { render :nothing => true, :status => :forbidden and return false} 
      end
    end
    return true
  end
  
  def require_user_or_anonymous
    return require_user(:anonymous => true)
  end

  def require_no_user
    if current_user
      store_location
      flash[:notice] = "You must be logged out to access this page"
      redirect_to root_url
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
    if not current_user
      redirect_to new_user_session_url(:next => request.path)
      return false
    elsif not admin?
      render "application/admin"
      return false
    end
  end
  
  def chrome?
    request.user_agent.try(:include?,"Chrome") && !request.user_agent.try(:include?, "Mobile")
  end
  
  def firefox?
    request.user_agent.try(:include?, "Firefox")
  end
  
  def extension?
    request.headers["x-scoopinion-extension-version"] || request.cookies["scoopinion-extension-version"]  
  end
  
  def current_user_languages
    languages = (LanguageGuesser.guess(request)).uniq

    if ! languages.include?("fi") && ! languages.include?("en")
      languages << "en"
    end
        
    if current_user      
      languages = current_user.feed_languages
    end

    languages
  end
  
  
  def weekend?
    Time.now.utc.saturday? || Time.now.utc.sunday?
  end

  # Helper to display conditional html tags for IE
  # http://paulirish.com/2008/conditional-stylesheets-vs-css-hacks-answer-neither
  def html_tag(attrs={})
    attrs.symbolize_keys!
    html = ""
    html << "<!--[if lt IE 7]> #{ tag(:html, add_class('lt-ie9 lt-ie8 lt-ie7', attrs), true) } <![endif]-->\n"
    html << "<!--[if IE 7]>    #{ tag(:html, add_class('lt-ie9 lt-ie8', attrs), true) } <![endif]-->\n"
    html << "<!--[if IE 8]>    #{ tag(:html, add_class('lt-ie9', attrs), true) } <![endif]-->\n"
    html << "<!--[if gt IE 8]><!--> "

    if block_given? && defined? Haml
      haml_concat(html.html_safe)
      haml_tag :html, attrs do
        haml_concat("<!--<![endif]-->".html_safe)
        yield
      end
    else
      html = html.html_safe
      html << tag(:html, attrs, true)
      html << " <!--<![endif]-->\n".html_safe
      html
    end
  end

  private

  def add_class(name, attrs)
    classes = attrs[:class] || ""
    classes.strip!
    classes = " " + classes if !classes.blank?
    classes = name + classes
    attrs.merge(:class => classes)
  end

end
