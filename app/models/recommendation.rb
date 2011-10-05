require 'transitions'

class Recommendation < ActiveRecord::Base
  
  include ActiveRecord::Transitions
  
  belongs_to :user, :inverse_of => :recommendations
  belongs_to :article
  
  validates :article_id, { 
    :uniqueness => { :scope => :user_id }
  }
  
  state_machine do
    state :new
    state :read
    state :expired
  end
  
end
