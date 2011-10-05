class Feedback < ActionMailer::Base
 def email_feedback(message)
   @message = message
   mail(
     :to => 'feedback@privatemind.fi',
     :from => 'feedback@scoopinion.com',
     :subject => 'New Feedback',
     :content_type => 'text/plain'
   ).deliver
 end
end
