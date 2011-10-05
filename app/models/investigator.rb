class Investigator < BadgeType
  
  def self.badge_name
    "Investigator"
  end
  
  def self.after_create(record)
    if record.class == Visit && record.article && record.article.finder == record.user
      self.maybe_award(record.article.finder)
    end
  end
  
  def self.step(n)
    return 3 if n == 1
    return 15 if n == 2
    return 60 * ((n**1.5)-2)
  end
  
  def self.points_for(user)
    user.articles.where(:finder_id => user.id).count
  end
  
end
