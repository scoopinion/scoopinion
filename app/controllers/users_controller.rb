class UsersController < ApplicationController

  skip_before_filter :verify_authenticity_token, :only => [:create]

  respond_to :json, :html
  
  def index
    if params[:tag]
      render :partial => "users/list", :locals => { :users => Tag.find_by_name(params[:tag]).readers.take(10) }
    end
  end
  
  def show
    @user = User.find_by_id params[:id]
    @feed = @user.visits.limit(12)
    
    respond_with(@user) do |format|
      format.json { render :json => @user }
      format.html
    end
  end

  def new
    @user = User.new
  end
  
  def update
    @user = User.find params[:id]
    if @user == current_user
      if params[:user][:extension]
        @user.extension_installed_at = Time.now
        @user.save
      end
      params[:user][:languages].each do |lang|
        @user.languages.create(:language => lang[0])
      end
    end

    respond_with(@user) do |format|
      format.json { render :json => @user }
    end
  end
  
  def create
    # Fetching user data from FB registration form using facebook_registration gem
    fb_form_data = FacebookRegistration::SignedRequest.parse(params["signed_request"])

      # Check if user logged in using FB credentials
    if fb_form_data
      @user = User.new

        # If the FB registration form is used, save authentication data for user
      if fb_form_data['user_id']
        @authentication = @user.authentications.build(:provider => 'facebook', :uid => fb_form_data['user_id'])
      end

      @user.username = fb_form_data['registration']['name']
      @user.email = fb_form_data['registration']['email']

      if @user.authenticated?
        @user.crypted_password = ''
        @user.password_salt = ''
        @user.login = fb_form_data['registration']['email']
      else
        @user.password = fb_form_data['registration']['password']
        @user.password_confirmation = fb_form_data['registration']['password']
        @user.login = fb_form_data['registration']['username']
      end
    else
      @user = User.new(params[:user])

    end

    if @user.save
      flash[:notice] = "Login successful!"
      redirect_back_or_default "/extension"
    else
      render :action => :new
    end
  end

end



