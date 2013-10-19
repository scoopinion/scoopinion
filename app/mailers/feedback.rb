class Feedback < ActionMailer::Base
 def email_feedback(message, user, email=nil)
   @message = message
   sender = [user.display_name, email, user.id].detect{ |x| !x.blank? }
   @subject = "New Feedback from #{sender}"
   @email = [ user.email, email, "feedback@scoopinion.com" ].detect{ |x| !x.blank?}
   
   mail(
        :to => 'contact@scoopinion.com',
        :bcc => 'kobra@scoopinion.com',
        :from => @email,
        :subject => @subject,
        :content_type => 'text/plain'
   ).deliver
 end
end
