class UserLanguage < ActiveRecord::Base
  
  belongs_to :user
  
  validates :user_id, { 
    :presence => true,
    :uniqueness => { 
      :scope => :language
    }
  }
  
  validates :language, { 
    :presence => true
  }
end
