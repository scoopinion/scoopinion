# == Schema Information
# Schema version: 20110603153902
#
# Table name: articles
#
#  id           :integer         not null, primary key
#  url          :string(255)
#  title        :string(255)
#  visits_count :integer
#  created_at   :datetime
#  updated_at   :datetime
#  score        :integer
#

class Article < ActiveRecord::Base

  belongs_to :site, :counter_cache => true
  belongs_to :finder, :class_name => "User"
  
  has_many :visits, :order => "created_at ASC", :inverse_of => :article, :dependent => :destroy
  has_many :visitors, :through => :visits, :source => :user
  has_many :concealments, :class_name => "ArticleConcealment", :inverse_of => :article, :dependent => :destroy
  has_many :comments, :inverse_of => :article, :order => "created_at ASC", :dependent => :destroy
  has_many :article_tags
  has_many :tags, :through => :article_tags
  
  has_many :tag_predictions
  
  validates :url, {
      :uniqueness => true,
      :format => {:with => /\/[^\/]/}
  }

  validates_presence_of :title
  validates_uniqueness_of :title, :scope => :site_id

  attr_protected :score

  attr_accessor :referrer
  
  scope :newer_than, Proc.new{ |period| where("articles.created_at > ?", Time.now - period)}
  scope :in_languages, Proc.new{ |languages| includes(:site).where("sites.language IN (?)", languages) }
  
  before_create do
    comments_count = 0
  end
  
  AUTO_TAGS = { 
    :entertainment => [ "viihde" ],    
    :sports => [ "urheilu" ],
    "2011 norway attacks" => [ "breivik", "utoya", "utya" ],
    "helsinki" => [ "helsinki", "helsing" ],
    "finland" => [ "finland" ],
    "paywall" => [ "hs.fi/verkkolehti" ]
  }
  
  after_create do
    self.delay.auto_tag
    self.delay.guess_language!
  end
  
  def auto_tag
    AUTO_TAGS.each do |tag, keywords|
      tag_with(tag.to_s) if keywords.any? { |w| url.downcase.include? w}
    end
    
    BayesianTagger.delay.predict(self)
  end
  
  after_initialize do
    inject_site_specific_code
  end
  
  @@loaded_sites ||= { }
  
  def can_load_site_specific_code?
    begin
      return false unless self.site_id
      return true if @@loaded_sites[site_id]
      File.exist?("#{Rails.root}/app/models/sites/#{site_id}.rb")
    rescue ActiveModel::MissingAttributeError
      return false
    end
  end
  
  def inject_site_specific_code 
    return false unless can_load_site_specific_code?
    
    unless @@loaded_sites[site_id]
      require "sites/#{site_id}"
    end
    
    @@loaded_sites[site_id] = true  
    extend Kernel.const_get("Site#{site_id}")
  end
  
  def self.search(query)
    return [] unless query
    where("LOWER(title) like '%#{query.downcase.gsub(/\\/, '\&\&').gsub(/'/, "''")}%'").sort_by(&:hotness).reverse.take(20)
  end

  
  def self.feed(options = {})

    concealed = []
    blocked_tags = []
    
    options[:period] ||= 100.years
    options[:period] = options[:period].to_i
    
    options[:limit] ||= 50
    options[:limit] = options[:limit].to_i
    
    unless options[:order] || options[:sort]
      options[:sort] = "hotness"
    end
    
    

    feed = where("articles.created_at > ?", Time.now - options[:period]).where("(articles.language IN (?) OR (articles.language IS NULL AND sites.language IN (?)))", options[:languages], options[:languages])
    feed = feed.includes(:tags, :concealments, :site, :finder)
    
    if options[:limit] && !options[:sort]
      feed = feed.limit(options[:limit] * 10)
    end
        
    if options[:min_time]
      feed = feed.where("articles.average_time > ?", options[:min_time])
    end
    
    if options[:order]
      feed = feed.where("#{options[:order]} IS NOT NULL").order("#{options[:order]} DESC")
    end
    
    if options[:user]
      concealed = options[:user].concealed_articles.where("articles.created_at > ?", Time.now - options[:period])
      blocked_tags = options[:user].concealed_tags
      
      if options[:unread_only]
        concealed += options[:user].articles.newer_than(options[:period])
      end
    end
    
    if options[:tag] && options[:tag] = Tag.find_by_name(options[:tag])
      feed = feed.where("tags.id = ?", options[:tag].id)
    end
    
    feed.reject! { |a| concealed.include? a }
    
    unless options[:tag]
      blocked_taggings = ArticleTag.where("article_id IN (?)", feed).where("tag_id IN (?)", blocked_tags).includes(:article).map{ |at| at.article }
      feed.reject! { |a| blocked_taggings.include? a }
    end
    
    if options[:sort]
      feed.sort_by!{ |x| x.send(options[:sort]) }.reverse!
    end
        
    feed.take(options[:limit])

  end
  
  def self.cleanse_url(url)
    ["http://",
     "https://",
     /\?.*/,
     /\#.*/,
     /\/$/].inject(url) do |url, filter|
      url.gsub(filter, "")
    end
  end
  
  def update_finder
    self.finder = self.visits.order("created_at ASC").first.try(:user)
    self.save
  end
     
  
  def as_link
    return "" unless self[:url]
    u = read_attribute(:url)
    return u if u.start_with? "http://"
    return "http://" + u
  end

  def site_title
    return "" unless url
    url.split("/")[0]
  end

  def url=(url)
    self[:url] = self.class.cleanse_url(url)
  end

  def increment_score(amount)
    self.score ||= 0
    self.score = self.score + amount
  end

  def score
    self[:score] || 0
  end

  def visits_count
    self[:visits_count] || 0
  end

  def comments_count
    self[:comments_count] || 0
  end

  def pretty_title
    return nil unless self[:title]

    if site && site.truncate_leading_title
      return self[:title].gsub(/.* - /, "")
    end

    self[:title].gsub(/ \| .*/, "").gsub(/ - .*/, "")
  end

  def as_json(options={})
    super(options.merge(:methods => [:score]))
  end
  
  def interestingness
    return score / 2 if visits_count < 2
    return score
  end
  
  def hotness
    return 0 if score == nil || score.to_i == 0
    @hotness ||= (score + comments_count * 5) / (age + 10) ** 1.5
  end
  
  def average_time
    average = self[:average_time] || calculate_average_time!
    return false unless average
    accuracy = 30
    (average / accuracy).round * accuracy
  end
  
  def calculate_average_time!
    return 0 unless self.visits.any?
    update_attribute :average_time, visits.average(:total_time)
    return self[:average_time]
  end
  
  def language
    return self[:language] || site.try(:language)
  end
  
  def guess_language!
    self[:language] = guess_language
    self.save
  end
  
  def recalculate!
    self.visits.reload
    average = visits.average(:score) || 0
    visitor_score = 20 * (Math.log10(visits.count))
    self.score = average + visitor_score
    self.score = 0 unless valid?
    self.score = 0 unless self.visitors.any?
    self.calculate_average_time!
    self.calculate_average_visiting_time!
    self.save
  end
    
  def tag_with(string)
    tag = Tag.find_or_create_by_name(string)
    
    if tp = TagPrediction.where(:tag_id => tag.id, :article_id => id).first
      tp.state = "confirmed"
      tp.save
    else
      TagPrediction.create(:confidence => 1, :article => self, :tag => tag, :state => "confirmed")
      ArticleTag.create(:article => self, :tag => tag)
    end
  end
  
  def calculate_average_visiting_time!
    return created_at unless self.visits.any?
    self[:average_visiting_time] = Time.at(self.visits.map(&:created_at).compact.inject{ |sum, time| sum + time}.to_f / self.visits.count)
    self.save
    self[:average_visiting_time]
  end
  
  def average_visiting_time
    self[:average_visiting_time] ||= calculate_average_visiting_time!
  end
  
  def age
    (Time.now - average_visiting_time).to_f / 1.hour
  end
  
  def to_param
    "#{id}-#{site.try(:title).try(:parameterize)}-#{pretty_title.parameterize}"
  end
  
  def unique_image?
    image_url && Article.where(:image_url => image_url).count < 2
  end
  
  private
  
  def guess_language
    if !description && site
      return site.language
    end
    
    @@d ||= LanguageDetector.new
    body = "#{self.pretty_title} #{self.description}"
    @@d.detect(body)
  end
    
    
end
