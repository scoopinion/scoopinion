class Recommender
  
  def self.generate(user)
    
    user.recommendations.where(:state => :new).each do |r|
      if r.article && r.article.visitors.include?(user)
        r.update_attributes(:state => :read) 
      elsif Time.now - r.created_at > 10.minutes
        r.update_attributes(:state => :expired)
      end
    end
        
    return if user.recommendations.where(:state => "new").count > 0
    
    return if user.visits.count < 5
    
    a = nil
         
    [ 30, 15, 0 ].each do |min_score|
      a = self.recommend(user, min_score)
      break if a
    end
    
    user.recommendations.create(:article => a)
    
    user.recommendations.reload
  end
  
  def self.recommend(user, min_score)
    blocked_tags = user.concealed_tags
    languages = user.languages.map(&:language)
    
    pool = Article.newer_than(3.days).in_languages(languages).where("image_url IS NOT NULL").where("image_url != ''").where("articles.score > ?", min_score).includes(:visitors)
    
    pool.sort_by! { |x| -self.personal_hotness(x, user) }
    
    blocked_taggings = ArticleTag.where("article_id IN (?)", pool).where("tag_id IN (?)", blocked_tags).includes(:article).map{ |at| at.article }
    
    a = pool.detect do |a| 
      ! (blocked_taggings.include?(a) || user.recommended_articles.include?(a) || a.visitors.include?(user) || user.concealed_articles.include?(a))      
    end
  end
  
  def self.personal_hotness(article, user)
    (Math.log10(self.personal_interestingness(article, user)) + (article.average_visiting_time.to_f - 1304208000)/ 100000.0).round(7)
  end
  
  def self.personal_interestingness(article, user)
    return (article.score) * self.friend_fraction(user, article) + article.tags.map{ |t| user.tags.where(:id => t.id).count * 20}.inject(0){ |sum, x| sum + x}
  end
  
  def self.friend_fraction(user, article)
    (article.visitors.select{ |v| user.friend_of?(v)}.count.to_f + 1) / (article.visits_count + 1)
  end
  
  def self.tag_factor(article, user)
    article.tags.map{ |t| user.tags.where(:id => t.id).count.to_f / user.tags.count }.inject(0){ |sum, x| sum + x}
  end

  
end
