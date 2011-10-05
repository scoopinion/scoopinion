class BadgeType
    
  def self.maybe_award(user)
    return unless user
    new_level = level_of(user)
    return unless new_level
    user.badges.create(:level => new_level, :badge_type => self.badge_name)
  end
    
  def self.level_of(user)
    points = self.points_for(user)
    
    return false unless points > 0
    
    level = false
    n = 1
    
    while true
      return level if points < self.step(n).floor 
      level = n
      n = n + 1
    end
  end
end
