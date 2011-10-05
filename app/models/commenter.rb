class Commenter < BadgeType
  
  def self.badge_name
    "Commenter"
  end

  def self.after_create(record)
    if record.class == Comment
      self.maybe_award(record.user)
    end
  end
  
  def self.step(n)
    return 1 if n == 1
    return 3 if n == 2
    return 10 * ((n ** 1.5)-2)
  end
  
  def self.points_for(user)
    user.comments.count
  end
  
end
