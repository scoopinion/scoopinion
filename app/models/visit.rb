# == Schema Information
# Schema version: 20110603153902
#
# Table name: visits
#
#  id         :integer         not null, primary key
#  user_id    :integer
#  article_id :integer
#  created_at :datetime
#  updated_at :datetime
#  score      :integer
#

class Visit < ActiveRecord::Base
  belongs_to :article, :counter_cache => true, :touch => true
  belongs_to :user
  
  has_one :site, :through => :article
  
  has_many :tags, :through => :article
  
  validates :article_id, :presence => true
  validates :user_id, :presence => true, :uniqueness => { :scope => :article_id }
  
  before_create do
    if user
      return false if user.concealed?(article)
    end
  end
  
  before_save do
    self.score = experimental_score
  end
  
  after_save do
    if self.score_changed? && article
      article.delay.recalculate!
    end
  end
  
  after_destroy do
    if article
      article.delay.recalculate!
      article.delay.update_finder
    end
  end
  
  after_create do
    if user && site
      user.guess_language(site.language)
    end
  end
  
  def score=(score)
    self[:score] = score
  end
  
  def score
    self[:score] || 0
  end
  
  def to_json(options={})
    { 
      :id => id,
      :total_time => total_time
    }.to_json
  end
  
  def via
    return false unless referrer
    return :scoopinion if referrer.include? "scoopinion.com"
    return :facebook if referrer.include? "facebook.com"
    return :twitter if referrer.include? "twitter.com"
    return :reddit if referrer.include? "reddit.com"
  end

  def self.average(attribute)
    where("created_at > ?", Time.now - 7.days).average(attribute)
  end
  
  BEHAVIOR_VARS =  
    { 
    :total_scrolled => 0.1,
    :link_click => 1,
    :right_click => 1,
    :mouse_move => 1,
    :link_hover => 1,
    :arrow_up => 3,
    :scroll_up => 3 
  }
  
  def experimental_score
    score = BEHAVIOR_VARS.inject(0) do |sum, var| 
      sum + [var[1] * (self.send(var[0]) || 0), 500].min
    end || 0
    
    score += ((total_time || 0) * ((arrow_down || 0) * 3 + (scroll_down || 0) * 2)) ** 0.5
    score /= 20
    score = [ score, 100 ].min
  end
  
end
