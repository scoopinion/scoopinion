require 'transitions'

class Notification < ActiveRecord::Base
  
  include ActiveRecord::Transitions
  
  belongs_to :user
  belongs_to :subject, :class_name => "User"
  belongs_to :reason, :polymorphic => true
  
  validates :user_id, { 
    :uniqueness => { :scope => [ :reason_id, :reason_type ] }
  }
  
  state_machine do
    state :new
    state :read
  end

  scope :unread, where("state = 'new'")
  scope :not_by, Proc.new{ |user| where("subject_id != ? OR subject_id IS NULL", user.id)}
  
end
