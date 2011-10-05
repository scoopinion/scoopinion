class Evangelist < BadgeType
  
  def self.badge_name
    "Evangelist"
  end
   
  def self.after_create(record)
    if record.class == Visit && record.article && record.article.visitors
      record.article.visitors.map do |user|
        self.maybe_award(user)
      end
    end
  end
  
  def self.step(n)
    return 2 if n == 1
    return 10 if n == 2
    return 50 * ((n**1.5)-2)
  end
  
  def self.points_for(user)
    user.fellow_visits
      .where("(visits.referrer LIKE '%huome.net%' OR visits.referrer LIKE '%scoopinion.com%')")
      .where("visits.user_id != ?", user.id)
      .select do |v| 
      own_visit = user.visits.find_by_article_id(v.article_id)
      return false unless own_visit
      v.created_at > own_visit.created_at
    end.count
  end
  
end
