class Friendship < ActiveRecord::Base
  belongs_to :user
  belongs_to :friend, :class_name => "User"

  def compatibility(options={ })
    if ! self[:compatibility] || compatibility_expired?
      unless options[:recalculate] == false
        calculate_compatibility_later
      end
      return self[:compatibility] || -1
    end
    self[:compatibility]
  end
  
  def compatibility=(comp)
    self[:compatibility] = comp
    self.compatibility_updated_at = Time.now
  end
  
  def calculate_compatibility(force = false)
    return unless compatibility_expired? || force
    comp = user.calculate_compatibility_with(friend)
    self.compatibility = comp
    self.recalculation_scheduled = false
    self.save
    if inverse
      inverse.compatibility = comp
      inverse.recalculation_scheduled = false
      inverse.save
    end
  end
  
  def calculate_compatibility_later
    unless recalculation_scheduled
      delay.calculate_compatibility
      update_attribute(:recalculation_scheduled, true)
      inverse.update_attribute(:recalculation_scheduled, true)
    end
  end
  
  def compatibility_expired?
    compatibility_updated_at.nil? || Time.now - compatibility_updated_at > 1.day
  end
  
  def inverse
    @inverse ||= Friendship.where(:user_id => friend_id, :friend_id => user_id).first
  end
  
  def as_json(options={ })
    { 
      :compatibility => compatibility,
      :user_id => user_id,
      :friend_id => friend_id,
      :id => id
    }
  end
  
end
