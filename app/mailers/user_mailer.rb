class UserMailer < ActionMailer::Base
  default from: "Scoopinion <noreply@scoopinion.com>"
  
  def welcome(user)
   @message = message
   mail(
     :to => user.email,
     :subject => 'Welcome to Scoopinion!',
     :content_type => 'text/html'
   ).deliver    
  end
  
end
