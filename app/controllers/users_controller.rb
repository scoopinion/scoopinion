class UsersController < ApplicationController

  skip_before_filter :verify_authenticity_token, :only => [:create, :update, :show]
  
  before_filter :require_no_user, :only => [ :new ]
  before_filter :require_user_or_create_anonymous, :only => [ :new, :show ], :if => Proc.new { params[:action] == "new" || (params[:format] == "json" && params[:id] == "current" && !params[:check_only]) }
  
  respond_to :json, :html

  layout "distraction_free", only: [ :new, :update, :edit ]
  
  def index
    if params[:tag]
      render :partial => "users/list", :locals => { :users => Tag.find_by_name(params[:tag]).readers.take(10) }
    end
  end
  
  def show
    @user = current_user(:anonymous => true) if params[:id] == "current"
    @user ||= User.find_by_single_access_token(session[:api_key]) if session[:api_key]
    @user ||= User.find_by_id(params[:id])
    
    if session[:api_key] && @user && @user.anonymous?
      if u = User.normal.find_by_single_access_token(session[:api_key])
        @user = u
      end
    end
    
    raise ActiveRecord::RecordNotFound unless @user
    
    respond_with(@user) do |format|
      format.html { redirect_to new_user_url if @user.anonymous? }
      format.json
    end
  end

  def new
    
    if params[:addon] && current_user(:anonymous => true) && current_user(:anonymous => true).created_at < Time.utc(2012,12,27)
      redirect_to new_user_session_url and return
    end
    
    @user = current_user(:anonymous => true)
    @subheading_test = ab_test("subheading_users_new", [ true, false ], :conversion => "create_account")
    @facebook_promise_test = ab_test("facebook_promise_users_new", [ true, false ], :conversion => "create_account")
    if !params[:addon]
      @footer_test = ab_test("footer_users_new", [ true, false ], :conversion => "create_account")
    else
      @footer_test = true
    end
  end
  
  def edit
    @user = User.find params[:id]
    redirect_to new_user_url unless @user == current_user(:anonymous => true)
  end

  def update
    anonymous_user = current_user ? nil : current_user(anonymous: true)
    
    if anonymous_user && !params[:user_credentials]
      create
      return
    end

    @user = User.find params[:id]

    if @user == current_user(:anonymous => true)
      extension_was = @user.extension_installed_at
      
      @user.update_attributes(params[:user])
      
      if @user.extension_installed_at && !extension_was
        Abingo.identity = @user.abingo_identity
        bingo!("install_addon")
        bingo!("install_addon_or_sign_up")
      end
    else
      head :status => 403 and return
    end
    
    respond_with(@user) do |format|
      format.json { render :json => @user }
      format.html { redirect_to introduction_path }
    end
        
  end
  
  def create
    
    return if current_user
    
    if !current_user(:anonymous => true) && params[:user][:anonymous] && request.xhr?
      @current_user = User.create_anonymous(:locale => I18n.locale)
      @current_user.set_abingo_identity(session[:abingo_identity])
      @current_user_session = UserSession.new(:user => @current_user)
      @current_user_session.save
      render :json => { :status => :ok } and return
    end
    
    if current_user(:anonymous => true)
      @user = current_user(:anonymous => true)
    else
      @user = User.new
      @user.set_abingo_identity(session[:abingo_identity])
    end
    
    additional_params = {
      anonymous: false, 
      signup_completed_at: Time.now, 
      user_analytics_item_attributes: { 
        referrer: session[:referrer], 
        entry_point: session[:entry_point] 
      }
    }
    @user.update_attributes(params[:user].merge(additional_params))

    bingo!("create_account")
    bingo!("install_addon_or_sign_up")
    
    if @user.save
      flash[:notice] = "Login successful!"
      redirect_to introduction_path
    else
      @user.anonymous = true
      render @user.authenticated? ? :edit : :new
    end
  end
  
  private
  
  def single_access_allowed?
    true
  end

end
