class UserObserver < ActiveRecord::Observer
  
  observe :user, :comment, :article, :visit
  
  BADGES = [ Commenter, Reader, Investigator, Evangelist, Loyalist ]
  
  def after_create(record)
    BADGES.each do |b|
      b.delay.after_create(record)
    end
  end
  
end
