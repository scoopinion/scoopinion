class Reader < BadgeType
  
  def self.badge_name
    "Reader"
  end
  
  def self.after_create(record)
    if record.class == Visit
      self.maybe_award(record.user)
    end
  end
  
  def self.step(n)
    return 5 if n == 1
    return 25 if n == 2
    return 100 * ((n**1.5)-2)
  end
  
  def self.points_for(user)
    return 0 unless user.visits
    user.visits.count
  end
  
end
