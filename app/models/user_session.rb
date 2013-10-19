class UserSession < Authlogic::Session::Base
  find_by_login_method :find_by_login_or_email
  
  def remember_me_for
    10.years
  end

end
