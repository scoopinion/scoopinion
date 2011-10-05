class UserSession < Authlogic::Session::Base
  
  def remember_me_for
    10.years
  end

end
