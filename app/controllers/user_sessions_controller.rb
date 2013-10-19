class UserSessionsController < ApplicationController

  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy

  def index
    redirect_to root_url
  end 

  def new
    @user_session = UserSession.new
  end

  def create
    
    params[:user_session][:login].try :downcase!
    
    if @u = User.normal.find_by_email(params[:user_session][:login])
      params[:user_session][:login] = @u.email
    end
    
    params[:user_session][:remember_me] = true
    
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      flash[:notice] = "Login successful!"
      redirect_to params[:next] || root_url
    else
      render :action => :new 
    end
  end

  def destroy
    current_user_session.destroy
    flash[:notice] = "Logout successful!"
    redirect_to root_url
  end

end
