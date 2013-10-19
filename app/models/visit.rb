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

require 'delayed_job_finder'

class Visit < ActiveRecord::Base
  
  include DelayedJobFinder
  
  belongs_to :article, :counter_cache => true, :touch => true
  belongs_to :user, :counter_cache => true, :touch => true
  
  has_one :site, :through => :article
  has_many :authorships, :through => :article
  has_many :authors, :through => :article
  
  has_many :tags, :through => :article
  
  validates :article_id, :presence => true
  validates :user_id, :presence => true, :uniqueness => { :scope => :article_id }
  
  scope :solicited, :conditions => { :referred_by_scoopinion => true }
  scope :unsolicited, where { (referred_by_scoopinion == false) | (referred_by_scoopinion == nil ) }
  
  before_create do
    if user && article
      return false if user.concealed?(article)
    end
    true
  end
  
  before_save do
    check_if_referred_by_scoopinion!
    true
  end
  
  after_save do
    if self.score_changed? && article && history_item_id == nil
      article.delay.recalculate!
    end
    if self.heatmap_changed?
      self.delay.calculate_score!
    end
  end
  
  after_destroy do
    if article
      article.delay.recalculate!
    end
  end
  
  after_create do
    if user && site && !user.feed_languages.include?(site.language)
      user.delay.guess_language(site.language)
    end
  end
  
  def check_if_referred_by_scoopinion!
    self.referred_by_scoopinion = (referrer && ((referrer =~ /www\.scoopinion\.com/) != nil || (referrer =~ /huome\.net/) != nil ))
  end
  
  def score=(score)
    self[:score] = score
  end
  
  def referrer=(new_referrer)
    if self[:referrer].blank?
      self[:referrer] = new_referrer
    end
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
  
  def total_time=(t)
    self[:total_time] = [ 1800, t.try(:to_i) || 0 ].min
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
  
  def words_read
    @words_read ||= calculate_words_read
  end
  
  def calculate_words_read
    return 0 if total_time == nil
    if heatmap == nil
      return 0
      avg = article.visits.average(:total_time)
      return 0 if avg == 0
      maximum = [0, (total_time - 5) * (300 / 60)].max
      raw = (article.word_count * self.total_time / avg).to_i
      return [ raw, maximum ].min
    end
    return 0 unless heatmap && article.word_count && article.word_count > 0
    return 0 unless total_time
    maximum = [0, (total_time - 5) * (300 / 60)].max
    raw = (article.word_count * (heatmap.split(",").select{ |x| x.to_i > 25 }.count / 100.0)).to_i
    [ raw, maximum ].min
  end
  
  def calculate_progress
    if words_read > 0
      self.progress = (words_read / article.word_count.to_f) * 100 rescue nil
    else
      self.progress = 0
    end
  end
  
  def calculate_score!
    calculate_score
    calculate_progress
    save
  end
  
  def calculate_score
    if ! self.heatmap
      self.score = 0
      return
    end
    n = (words_read / 250.0).round
    self.score = [0, [ (n + (n - 1)) * 2, 100 ].min].max
  end
  
end
