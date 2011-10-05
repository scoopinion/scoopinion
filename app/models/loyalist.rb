class Loyalist < BadgeType
  
  def self.badge_name
    "Loyalist"
  end
  
  def self.after_create(record)
    if record.class == Visit
      self.maybe_award(record.user)
    end
  end
  
  def self.step(n)
    return 4 if n == 1
    return 20 if n == 2
    return 100 * ((n**1.5)-2)
  end
  
  def self.points_for(user)
    return 0 unless user.visits
    user.visits.where("(visits.referrer LIKE '%huome.net%' OR visits.referrer LIKE '%scoopinion.com%')").count
  end
  
end
