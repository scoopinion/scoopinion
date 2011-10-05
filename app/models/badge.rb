class Badge < ActiveRecord::Base
  belongs_to :user
  
  has_many :notifications, :as => :reason, :dependent => :destroy
  
  after_create :notify
  
  validates_uniqueness_of :user_id, :scope => [ :badge_type, :level ]
  
  private
  
  def notify
    if level_changed?
      Notification.create(:reason => self, :user => user)
    end
  end

end
