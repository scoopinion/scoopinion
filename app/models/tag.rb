class Tag < ActiveRecord::Base
  has_many :article_tags
  has_many :articles, :through => :article_tags
  has_many :visitors, :through => :articles
  has_many :tag_predictions
  
  belongs_to :supertag, :class_name => "Tag"
  
  validates :name, { 
    :uniqueness => true
  }
  
  after_save do 
    if supertag
      article_tags.each{ |at| at.update_attribute(:tag_id, supertag_id) }
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
  
  def hotness
    return 0 unless articles.count > 0
    hottest = articles.sort_by(&:hotness).reverse.take(30)
    hottest.inject(0){|sum,a| sum + a.hotness} / 30.0
  end
  
  def readers
    visitors.uniq.map do |user|
      seconds = Visit.includes(:tags).where("visits.created_at > ?", Time.now - 1.month).where(:user_id => user.id).where("tags.id = ?", id).sum(:total_time)
      [ user, seconds ]
    end.sort_by{ |a| -a[1]}
  end

end
