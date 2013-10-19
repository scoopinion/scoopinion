class Tag < ActiveRecord::Base
  
  has_many :article_tags, :dependent => :destroy
  has_many :articles, :through => :article_tags
  has_many :visitors, :through => :articles

  include Concealable
  
  belongs_to :illustrating_article, :class_name => "Article"
  
  belongs_to :supertag, :class_name => "Tag"
  
  validates :name, { 
    :uniqueness => true
  }
  
  after_save do 
    if supertag
      article_tags.update_all(:tag_id => supertag_id)
    end
  end
  
  def name=(new_name)
    self[:name] = new_name.downcase
    self[:parameter] = self.to_param
  end
  
  def to_param
    name.parameterize
  end
  
  def display_name
    name.try(:titleize) || parameter.humanize.titleize    
  end
    
  def recalculate!
    return 0 unless articles.count > 0
    self.hotness = articles.order("hotness desc").limit(30).sum(:hotness) / 30.0
    if !self.illustrating_article || illustrating_article_freshness > 1.hour
      self.update_illustrating_article
      self.illustrating_article_updated_at = Time.now
    end
    self.save
  end
  
  def readers
    visitors.uniq.map do |user|
      seconds = Visit.includes(:tags).where("visits.created_at > ?", Time.now - 1.month).where(:user_id => user.id).where("tags.id = ?", id).sum(:total_time)
      [ user, seconds ]
    end.sort_by{ |a| -a[1]}
  end
  
  def update_illustrating_article
    self.illustrating_article = articles.where("image_width >= 350").where("image_height >= 200").order("hotness desc").limit(50).detect{ |a| a.image_width >= a.image_height * 1.3 }
  end

  def image_url
    illustrating_article.try(:image).try(:url)
  end
  
  def illustrating_article_freshness
    Time.now - self.illustrating_article_updated_at
  end
  
  def to_s
    name.titleize
  end
  
end
