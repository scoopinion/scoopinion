class AuthenticationsController < ApplicationController
  def create
    @user = User.find_or_new_by_auth_hash_or_current_user(auth_hash, current_user(:anonymous => true), session[:abingo_identity])
    if @user.save
      bingo!("create_account") if @user.new_user
      sign_in
      if original_params[:close] == "true"
        render :close_popup, layout: false
      else
        redirect_to(params[:state] || (@user.new_user ? introduction_path : root_path))
      end
    elsif @user.errors.get(:email)
      @user.update_to_anonymous!
      redirect_to edit_user_path(@user)
    else
      render :failure
    end
  end

  def destroy
    @authentication = current_user.authentications.find(params[:id])
    @authentication.destroy
    flash[:notice] = "Successfully destroyed authentication."
    redirect_to authentications_url
  end

  def failure
    redirect_to params[:origin] if params[:origin]
  end

  private
  
  def auth_hash    
    request.env["omniauth.auth"]
  end

  def original_params
    (request.env['omniauth.params'] || {}).symbolize_keys
  end

  def sign_in
    unless current_user and current_user == @user
      user_session = UserSession.new(User.find_by_single_access_token(@user.single_access_token))
      user_session.remember_me = true
      user_session.save
    end
  end
end
