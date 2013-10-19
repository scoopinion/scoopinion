# -*- coding: utf-8 -*-
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

require 'open-uri'
require 'timeout'
require 'carrierwave/orm/activerecord'
require 'base_62'
require 'statistics'
require 'delayed_job_finder'

class Article < ActiveRecord::Base
  
  REFERRED_SCORE_COEFFICIENT = (ENV["REFERRED_SCORE_COEFFICIENT"] || 0.3).to_f
  
  include ActionView::Helpers::SanitizeHelper 

  include Concealable
  include DelayedJobFinder
  
  belongs_to :site, :counter_cache => true
  belongs_to :finder, :class_name => "User"
  
  has_many :visits, :order => "created_at ASC", :inverse_of => :article, :dependent => :delete_all
  has_many :visitors, :through => :visits, :source => :user

  has_many :article_tags, :dependent => :delete_all
  has_many :tags, :through => :article_tags
  has_many :article_referrals, :foreign_key => :article_id
  has_many :media_references
  has_many :referring_articles, :through => :article_referrals, :source => :referrer
  has_many :indirect_visits, :through => :referring_articles, :source => :visits
  has_many :bookmarks, :dependent => :delete_all
  
  has_many :reverse_article_referrals, :class_name => "ArticleReferral", :foreign_key => :referrer_id, :dependent => :delete_all
  has_many :sources, :through => :reverse_article_referrals, :source => :article
  
  has_many :authorships, :dependent => :delete_all
  has_many :authors, :through => :authorships
  
  has_many :alternate_urls, :dependent => :delete_all
  
  has_one :html_document, :dependent => :delete
  
  scope :with_tag, Proc.new{ |tag| joins(:tags).where{ tags.name == tag } }
  
  mount_uploader :content, TextUploader
  mount_uploader :image, ImageUploader
  
  attr_accessor :source
  
  def author
    authors.first
  end
  
  def body
    content.to_s || find_body
  end
  
  def body=(new_body)
    content.save(new_body) 
  end
  
  def short_id
    Base62.to_s(self.id).try :reverse
  end
  
  def self.find_by_short_id(short_id)
    find_by_id(Base62.to_i(short_id.reverse))
  end

  
  def migrate_old_body!
    content.save(self[:body]) if self[:body]
    save
  end
  
  validates :url, {
    :presence => true,
    :uniqueness => true,
    :format => {:with => /\/[^\/]/}
  }

  attr_accessor :referrer, :mailing_id
  
  scope :in_languages, Proc.new{ |languages| includes(:site).where("(articles.language IN (?) OR (articles.language IS NULL AND sites.language IN (?)))", languages, languages) }
  scope :fresher_than, Proc.new{ |time| where{ average_visiting_time > time } }
  
  after_create do
    self.delay.find_metadata unless Rails.env.test?
  end
  
  after_save do
    if image_url_changed?
      self.delay.cache_image 
    end
  end
  
  def self.merge(id1, id2, options = { })
    
    old, new = [ id1, id2 ].map{ |id| find id }.sort_by { |a| a.created_at.to_s }
    
    return false unless old.title == new.title || options[:force] == true
    
    old.visits.where{ user_id.in(new.visitors)}.delete_all
    old.visits.update_all(:article_id => new.id)
    old.authorships.delete_all
    old.article_tags.delete_all
    old.alternate_urls.delete_all
    old.reverse_article_referrals.delete_all
    old.html_document.try(:delete)
    old.bookmarks.update_all(:article_id => new.id)
    old.delete
    new.visits.reload
    Article.update_counters new.id, :visits_count => new.visits.count
    new.alternate_urls.create(:url => old.url) rescue nil
    new.delay.recalculate!
    
    return new
    
  end
  
  def find_metadata
    self.scrape
    self.update_attributes(:crawled_at => Time.now)
    self.guess_language!
    self.detect_media_reference! if language == "fi"
    #self.find_source
  end
  
  def detect_media_reference!
    colonized = title.split(": ")
    return false if colonized.size < 2
    referred_site = Site.includes(:alternate_names).where{ (sites.name == colonized[0]) | (alternate_names.name == colonized[0]) }.first
    return false unless referred_site
    self.media_references.create(:site_id => referred_site.id)
    self.media_references.select{ |x| x.id != nil }
  end
    
  def self.search(query)
    return [] unless query
    where("LOWER(title) like '%#{query.downcase.gsub(/\\/, '\&\&').gsub(/'/, "''")}%'").sort_by(&:hotness).reverse.take(20)
  end

  def image_url=(new_image_url)
    if new_image_url
      new_image_url = "http://" + new_image_url unless ( new_image_url.start_with?("http://") || new_image_url.start_with?("https://") )
    end
    self[:image_url] = new_image_url
  end
  
  def cache_image
    begin
      self.remote_image_url = self[:image_url]
      self.image.store!
      self.save
    rescue Exception => e
      puts e.message
      puts e.backtrace
      return false
    end
  end
  
  def image_url
    return self.image.thumb.url if self[:image]
    return self[:image_url]
  end

  def self.find_by_url(url)
    article = super(self.normalize_url(url))
    
    unless article
      article = AlternateUrl.where(:url => url).first.try :article
    end
    
    unless article
      if site = Site.find_by_full_url(url)
        article = Article.create(:site => site, :url => self.normalize_url(url))
      end
    end
    article
  end
  
  def self.normalize_url(url)
    
    return nil unless url
    
    unless url.include?("%")
      url = URI.encode(url).gsub("%23", "#")
    end
    
    begin
      uri = URI.parse(url)
    rescue URI::InvalidURIError
      return ""
    end
    
    query_string = ""
    if uri.query
      query_string = CGI.parse(uri.query)
      query_string = query_string.select do |key, value|
        [ "id", "oid", "article_id", "articleid", "sivu", "jako" ].include? key
      end
      query_string = query_string.to_query.gsub("%5B%5D", "")
    end
    
    path = uri.path || ""
    
    (uri.host || "") + path.gsub(/\/*$/, "").gsub(/\/\/+/, "/") + (query_string.empty? ? "" : "?#{query_string}")
  end
  
  def weighed_score(user, calculate = false)
    visits.map do |v|
      v.score * [ 0.005, UserCompatibility.get(user.id, v.user_id, :calculate => calculate) ].max
    end.sum
  end
     
  def remote_url
    return "" unless self[:url]
    u = read_attribute(:url)
    return u if u.start_with? "http://"
    return "http://" + u
  end

  def url=(url)
    self[:url] = self.class.normalize_url(url)
  end
  
  def as_json(options={})
      super(options.merge(:methods => [:score, :content_selector, :rating]))
  end
  
  def selectors
    { 
      :heatmap => content_selector,
      :body => body_selectors,
      :title => title_selectors,
      :author => author_selectors,
      :published_at => published_at_selectors
    }
  end
  
  def scraping_rules
    @scraping_rules ||= 
      begin
        rules = site.try(:scraping_rules_hash) || { }
        ScrapingRule::ELEMENT_TYPES.each do |et|
          rules[et] ||= []
          rules[et].concat(Scraper.scraping_rules(et))
        end
        rules
      end
  end
  
  def author_selectors
    scraping_rules["author"]
  end
  
  def title_selectors
    scraping_rules["title"]
  end
  
  def body_selectors
    scraping_rules["body"]
  end
  
  def content_selector
    scraping_rules["heatmap"]
  end
  
  def published_at_selectors
    scraping_rules["published_at"]
  end
  
  def average_time
    average = self[:average_time] || calculate_average_time!
    return false unless average
    accuracy = 30
    (average / accuracy).round * accuracy
  end
  
  def calculate_average_time!
    return 0 unless self.visits_count > 0
    self[:average_time] = visits.average(:total_time)
  end
  
  def language
    return self[:language] || site.try(:language)
  end
  
  def guess_language!
    self[:language] = guess_language
    self.save
    self[:language]
  end
  
  def recalculate!
    self.calculate_score!
    self.calculate_average_time!
    self.calculate_average_visiting_time!
    self.calculate_hotness!
    self.update_suitability
    self.save
  end
  
  def update_suitability
    self.suitable = title && summary && !summary.empty?
    self.featured = suitable && image_width && image_width > 200 && image_height && image_width > image_height
  end
  
  def maybe_tweet
    if self.score >= 30 && self.score_was < 30
      Tweeter.tweet(self)
    end
  end
  
  def self.average_score
    Rails.cache.fetch("average_article_score", :expires_in => 1.hour) do
      Article.newer_than(1.week).where{ score > 1 }.average(:score) || 1.0
    end
  end
  
  def calculate_score!
    self.score = 
      self.visits.unsolicited.sum(:score) + self.visits.solicited.sum(:score) * REFERRED_SCORE_COEFFICIENT
    
    self.rating = [ (0.625 * (self.score.to_f || 0) / Article.average_score).round, 5 ].min
    
    return self.score
  end
  
  def popularity_controlled_score
    self.score.to_f / self.site.popularity
  end
  
  def calculate_hotness!
    if score == nil || score.to_i == 0
      self[:hotness] = 0
      return 
    end
    self[:hotness] = (Math.log10(score) + (average_visiting_time.to_f - 1304208000)/ 100000.0).round(7)
  end
  
  def tag_with(string)
    tag = Tag.where(:name => string).first || Tag.create(:name => string)
    return if self.tags.where(:id => tag.id).exists?    
    ArticleTag.create(:article => self, :tag => tag)
  end
  
  def calculate_average_visiting_time!
    if self.visits.unsolicited.none? && self.indirect_visits.unsolicited.none?
      self[:average_visiting_time] = created_at 
    else
      min = self.visits.unsolicited.minimum(:created_at) || self.created_at
      times = [ self.visits.unsolicited, self.indirect_visits.unsolicited ].map{ |x| x.pluck("visits.created_at") }.flatten
      diffs = times.map{ |x| x - min }
      self[:average_visiting_time] = min + diffs.avg
    end
  end
  
  def average_visiting_time
    self[:average_visiting_time] ||= calculate_average_visiting_time!
  end
  
  def to_param
    short_id
  end
  
  def unique_image?
    self[:image_url] && Article.where(:image_url => self[:image_url]).count < 2
  end
  
  def readthrough
    return nil unless visits.where("heatmap is not null").exists?
    return nil unless word_count
    (visits.where("heatmap is not null").map(&:words_read).tap{|a| a[0] = a.inject(:+) / a.size.to_f }[0] || 0.0) / word_count
  end
  
  def analytics_secret
    require "digest"
    Digest::MD5.hexdigest(created_at.to_s + "analytics")
  end
  
  def analytics_url
    "https://www.scoopinion.com/analytics/#{id}?secret=#{analytics_secret}"
  end
  
  def retrieve_html
    begin
      Timeout::timeout(200) do
        stream = open(remote_url)

        if stream.content_encoding.empty?
          raw = stream.read
        else
          raw = Zlib::GzipReader.new(stream).read
        end
        
        encoding = detect_encoding(raw)
        
        raw = raw.force_encoding(encoding).encode("utf-8")        
        
        if self.html_document
          self.html_document.update_attributes(:raw => raw)
        else
          self.html_document = HtmlDocument.create(:article => self, :raw => raw)
        end
      end
    rescue Exception => e
      ap e
      ap e.backtrace
      return false
    end
    
    return self.html_document.try(:raw)
  end
  
  def scrape
    retrieve_html unless self.html_document.try(:raw)
    return false unless self.html_document.try(:raw)
    
    find_author
    
    retval = {  
      :title => find_title,
      :image_url => find_image_url,
      :body => find_body,
      :description => find_description,
      :summary => create_summary,
      :published_at => @scraper.find_published_at,
      :authors => authors.map(&:name)
    }
    
    
    self.published_at = retval[:published_at]
    
    self.count_words
    
    self.update_suitability
    
    save
    
    self.delay.canonicalize_url
    
    retval
  end
  
  def canonicalize_url
    canonical = canonical_url
    return if !canonical || url == canonical
    
    if Article.where(:url => canonical).exists?
      puts "merging"
      Article.merge(id, Article.where(:url => canonical).first, :force => true)
    else
      old_url = url
      self.url = canonical
      alternate_urls.create(:url => old_url)
    end
  end
  
  def find_author
    init_scraper
    author_names = @scraper.find_author_names
    return unless author_names
    
    self.authors.clear
    
    return if self.url.split("/").count == 2 && self.url.split("/")[1].length <= 10 
    
    add_authors(author_names)
  end
  
  def add_authors(author_names)
    author_names.reject do |author_name|
      author_name.blank? || author_name == site.name || author_name.split(" ").length >= 6
    end.map do |author_name|
      author = Author.find_or_create_by_name(author_name.strip[0..254])
      self.authors << author unless self.authors.include? author
      author
    end
  end
  
  def tagged_with?(tag)
    article_tags.joins(:tag).where("tags.name" => tag).exists?
  end
    
  def find_title
    init_scraper
    @scraper.find_title.tap do |new_title|
      if new_title
        self[:title] = new_title[0..254]
      end
    end
    title
  end
  
  def original_image_url
    return nil unless image_url
    image.url(:thumb).try(:gsub, "thumb_", "")
  end
  
  def find_image_url
    init_scraper
    if (og = @doc.css("meta[property='og:image']")).any?
      self[:image_url] = og[0]['content']
    elsif (link = @doc.css("link[rel=image_src]")).any?
      self[:image_url] = link[0]['href']
    elsif (img = @doc.css("#dokumentti h6 img")).any?
      self[:image_url] = img[0]['src']
    elsif (img = @doc.css("link[rel=apple-touch-icon]")).any?
      self[:image_url] = img[0]['href']
    elsif (img = @doc.css("img.featured")).any?
      self[:image_url] = img[0]['src']
    elsif (img = @doc.css(".article_image img.shown")).any?
      self[:image_url] = img[0]['src']
    end
    
    if self.authors.count == 1 && self.authors[0].picture_url &&
        self.site.articles.where(:image_url => self[:image_url]).count > 5
      self[:image_url] = self.authors[0].picture.thumb.url
    end
    
    self[:image_url]
  end
  
  def find_description
    
    if self.body
      self[:description] = self.body.gsub("\n\n", "<br/><br/>").gsub("\n", "").split(" ")[0..100].join(" ").strip
      return self.description
    end
    
    if (og = @doc.css("meta[property='og:description']")).any?
      self[:description] = og[0]['content'].strip.gsub("\n", "")
    elsif (meta = @doc.css("meta[name=description]")).any? && meta[0]['content']
      self[:description] = meta[0]['content'].strip.gsub("\n", "")
    end     
    self.description
  end
  
  def find_body
    init_scraper
    return false unless @scraper
    new_body = @scraper.find_body
    self.body = new_body if new_body
  end 
  
  def title=(new_title)
    self[:title] ||= new_title
  end
  
  def description=(new_description)
    self[:description] ||= new_description
  end

  def clean_summary
    return [] unless summary
    summary.gsub("\n", "").gsub("<p>", "").gsub("</p>", "\n\n").split("\n\n").compact.select{|x| accept_paragraph?(x)}.map{|x| x.strip }.take(3)
  end  

  def create_summary!
    create_summary
    save
  end
  
  def create_summary
    paragraphs = summary_paragraphs
    return unless paragraphs
    self.summary = paragraphs.map{ |p| "<p>#{p}</p>" }.join
  end

  def accept_paragraph?(p)
    p = p.strip
    
    return false unless p =~ /\.$/ || p =~ /\?$/ || p =~ /\!$/ || p =~ /"$/ 
    return false if p =~ /^By .*, author of .* \(/
    return false if p.blank?
    return false if p["All rights reserved."]
    return false if p["Last updated at"]
    return false if p["Comments ("]
    return false if p["Navigate:"]
    return false if p["|"]
    return false if p["Recent Posts"]
    return false if p["at"] && p["2012"] && !p["."]
    return false if authors.detect{ |a| p[a.name] && p.length - a.name.length < 5 }
    return false if p["Post categories:"]
    return false if p["2012 by"]
    return false if p["suosikkilistalle tallentaminen vaatii kirjautumista"]
    return false if p["PUBLISHED"]
    return false if p[" Kuva: "]
    return false if p["KUVA:"]
    return false if p =~ /^Comments$/
    return false if p["Jaa Facebookissa"]
    return false if p =~ /GMT$/
    return false if p =~ /^Teksti.*Kuva/
    return false if p =~ /^Written by/
    return false if p =~ /^By.*[^.]$/
    return false if p =~ /^\[.*\]$/
    return false if p =~ /^Editor’s Note:/
    return false if p["Getty Images"]
    return false if p =~ /2012$/
    return false if p["PressRecommend"]
    return false if p =~ /^Kuva:/
    return false if p =~ /^Categories:/
    return false if p =~ /^ylin/
    return false if p =~ /^alin/
    return false if p =~ /p.m.$/
    return false if p =~ /a.m.$/
    return false if p["Copyright ©"]
    return false if p["Please turn on JavaScript"]
    true
  end  

  def summary_paragraphs
    
    source = self.body || self.description

    return [] unless source
    
    doc = Nokogiri::HTML(source.gsub(/([.?!])(\n|\r\r)/) { "#{$1}</p><p>" })
    paragraphs = doc.css("p").map{ |x| sanitize(x.text, :tags => []) }.select{ |x| x.strip.size > 0 }
    
    return [] unless paragraphs.any?

    paragraphs.select!{|p| accept_paragraph?(p) }    

    total = 0
    index = paragraphs.index(paragraphs.detect{ |p| total += p.size; total > 400})
        
    if total > 500 && index > 0
      index = index - 1
    end
    
    index = paragraphs.count - 1 if total <= 400
    
    if index == 0 && paragraphs[0].size > 400
      truncated = paragraphs[0][0..500]
      
      last_punctuation = truncated.reverse.index( /[.!?]/ )
      if last_punctuation == 0 || last_punctuation == nil
        last_punctuation = -1 
      else
        last_punctuation *= -1
      end
      return Array.wrap truncated[0..last_punctuation]
    end
    
    paragraphs[0..index]
  end
  
  def average_heatmap
    heatmaps = visits.where("heatmap is not null").map{ |v| v.heatmap }
    heatmaps = heatmaps.map{ |h| h.split(",").map{ |x| [ x.to_i, 255 ].min } }
    
    return [] unless heatmaps.size > 0
    
    average = []
    
    (0..(heatmaps[0].size-1)).each do |i|
      average[i] = heatmaps.inject(0){ |sum, h| sum + h[i] } / heatmaps.size
    end
    
    average
  end
  
  def to_s
    "#{id} #{site.try :name} - #{title} / #{authors.map(&:name).join(", ")}, #{score}p"
  end
  
  def check_for_duplicates
    duplicates = site.articles.where(:title => title)
    
    return false if duplicates.count == 1
    return false unless duplicates.any? { |a| a.url_is_canonical? }
    
    while duplicates.count > 1
      merged = Article.merge(duplicates.pop.id, duplicates.pop.id)
      duplicates << merged
    end
    
    return duplicates[0]
  end
  
  def url_is_canonical?
    url == canonical_url
  end
  
  def canonical_url
    init_scraper
    return nil unless @scraper
    Article.normalize_url(@scraper.find_canonical_url)
  end
  
  def find_source
    init_scraper
    return false unless @scraper
    ArticleReferral.transaction do
      self.sources.destroy_all
      links = @scraper.find_external_links
      links.reject! { |l| Article.normalize_url(l).split("/").size == 1 }
      links.reject! { |l| Site.host(l).split(".")[-2..-1] == Site.host(self.url).split(".")[-2..-1] }
      
      hosts = links.map { |l| Site.host(l).split(".")[-2..-1].join(".") }
      
      sites = hosts.uniq.map{ |x| Site.where{ url =~ "%#{x}"}.first }.compact
                    
      links.map! { |l| { :url => l, :site => sites.detect{ |x| l[x.url] }}}
      
      links.reject{ |l| l[:site] == nil }
      
      if links.size == 1      
        links.map! { |l| l.merge({ :article => Article.find_by_url(l[:url])})}
        links[0][:article].tap do |article|
          if article
            article.article_referrals.create(:referrer => self)
          end
        end
      end
    end
    self.sources.reload

    return self.sources
  end
  
  def words
    return [] unless self.body
    body.split(/[ \t\r\n]+/)
  end
  
  def count_words!
    count_words
    save
    return self[:word_count]
  end

  
  def count_words
    if self.words.length == 0
      return ((self.visits.average(:total_time) || 0) / 60.0) * 300
    end
    self.word_count = self.words.length
  end
  
  def scraper
    init_scraper unless @scraper
    @scraper
  end
  
  def doc
    init_scraper
    @scraper.doc
  end
  
  def compatibility_score(user)
    self.weighed_score(user) * compatibility(user)
  end
  
  def compatibility(user)
    visitors.map{ |x| x.calculate_compatibility_with(user)}.avg
  end
  
  def self.duplicate_urls
    Article.find_by_sql("select url, COUNT(url) from articles group by url having (count(url) > 1)").map(&:url)
  end
  
  def self.delete_or_merge_duplicates
    Article.duplicate_articles.where{ visits_count == 0 }.delete_all
    Article.merge_duplicates
  end
  
  def self.duplicate_articles
    where{ url.in(my { duplicate_urls }) }
  end
  
  def self.delete_empty_duplicates
    duplicate_articles.where(visits_count: 0).each(&:destroy)
  end
  
  def self.merge_duplicates
    duplicate_urls.each_with_progress do |url|
      Article.merge(*Article.where(url: url).pluck(:id), force: true)
    end
  end
  
  def milliseconds_per_word
    @msperword ||= word_count ? ((self.visits.average(:total_time) || 0) * 1000.0 / self.word_count).to_i : nil
  end
  
  def full_url
    "http://#{url}"
  end
  
  def final_url
    begin
      url = URI.parse(full_url)
      puts url
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.get(url.path)
      }
      res['location']
    rescue Exception => e
      return nil
    end
  end
  
  def save_final_url!
    final_url.tap do |url|
      if url && url != self.full_url
        alternate_urls.create(:url => url)
      end
    end
  end
  
  def self.find_most_read(visits_relation)
    by_title = visits_relation.joins(:article)
      .where{ articles.title != nil }
      .select("articles.title as title, articles.site_id as site_id, sum(visits.total_time) as total_time")
      .group("articles.site_id, articles.title")
      .order("total_time desc nulls last")
      .limit(1000)
      .map{|x| { title: x[:title], site_id: x[:site_id].to_i, total_time: x[:total_time].to_i } }
    
    by_title.reject!{ |x| self.title_blacklisted?(x[:title]) }
    
    result = by_title.map do |x|
      visits = Visit.joins(:article).includes(:article).where("articles.title" => x[:title], "articles.site_id" => x[:site_id]).map{ |v| [ v.total_time || 0, (v.article.word_count / 3 rescue 0) ].min }
      OpenStruct.new({ 
                       :title => x[:title],
                       :site_id => x[:site_id],
                       :sum => visits.sum,
                       :count => visits.count
                     })
    end
    
    result = result.sort_by(&:sum).reverse
    
    finals = []
    
    result.each do |x|
      if x.title && !self.title_blacklisted?(x.title) && x.sum > 0
        a = choose_article_for_title(x.title)
        finals << { 
          :title => x.title,
          :sum => x.sum.to_i,
          :id => a.id,
          :url => a.url
        }
      end
      if finals.size == 100
        return finals
      end
    end
    return finals
  end
  
  def blacklisted?
    
  end
  
  def self.title_blacklisted?(title)
    ids = Article.where(title: title).limit(100).pluck(:id)
    return true if ids.count > 5 && (ids.max - ids.min).abs > 10000
    url = choose_article_for_title(title).url
    return true if url.split("/").count < 3 && !url.match(/[0-9]/)
    return true if url.include?("/keskustelu/")
    return true if url.include?("areena.yle.fi")
    return true if url.include?("nytimes.com/marketing/")
    false
  end
  
  def self.choose_article_for_title(title)
    @@titles ||= { }
    @@titles[title] ||= begin
                          urls = Article.where(title: title).pluck(:url)
                          jako = urls.detect{ |x| x =~ /\?jako/ }
                          urls = urls.select{ |x| x =~ /\?jako/ } if jako
                          Article.find_by_url(urls.sort_by(&:length).first)
                        end
  end
  
  def self.choose_url_for_title(title)
    choose_article_for_title(title).url
  end
  
  def self.time_spent_lookup_table
    @time_spent_lookup ||= Rails.cache.fetch("article-lookup-table", :expires_in => 1.day) do
      self.make_time_spent_lookup_table
    end
  end
  
  def self.make_time_spent_lookup_table
    Hash[
         Visit.newer_than(3.months)
           .group("article_id")
           .select("article_id, sum(total_time)")
           .where{ total_time < 1000 }
           .having("count(*) > 2")
           .map{|x| [ x.article_id, x.sum.to_i ] }
        ] 
  end
  
  def self.warmup_time_spent_cache
    @time_spent_lookup = self.make_time_spent_lookup_table
    Rails.cache.write("article-lookup-table", @time_spent_lookup, :expires_in => 1.day)
    @time_spent_lookup.count
  end
  
  def self.time_spent(id)
    time_spent = time_spent_lookup_table[id]
    return time_spent unless time_spent.nil?
    time_spent = Visit.newer_than(3.months).where{ article_id == id}.where{ total_time < 1000 }.sum(:total_time)
    time_spent_lookup_table[id] = time_spent
    
    time_spent
  end
    
  private
  
  def init_scraper
    retrieve_html unless self.html_document.try(:raw)
    return false unless self.html_document.try(:raw)
    @doc ||= Nokogiri::HTML(self.html_document.try(:raw))
    @scraper ||= Scraper.new(@doc, self)
  end
  
  def guess_language
    
    require "language_standard"
    
    if section = site.sections.detect{ |s| s.include?(self.url) }
      if section.language
        return section.language 
      end
    end
    
    return site.language unless html_document

    init_scraper
    
    return site.language unless @doc && !@doc.css("html").empty?
    
    selectors = 
      [
       lambda { |d| d.xpath("/html/@lang")[0..1] },
       lambda { |d| d.css("html").try(:attr, "xml:lang").try :value }
      ]
       
    announced = selectors.map{ |s| s.call(@doc).to_s }.detect{ |x| x.length > 0 && x != "en" }
    
    if announced
      announced = announced.split("-")[0] if announced["-"]
      announced.downcase!
    end
    
    return announced if announced && LanguageStandard.codes.include?(announced)
    return site.language if site.language
  end
  
  def detect_encoding(raw)
    
    utf8_tells = [ "ä", "ö" ]
    
    return "utf-8" if utf8_tells.detect{ |x| raw.force_encoding("utf-8").include?(x) }
    
    require 'utf_8'
    
    html = Nokogiri::HTML(raw)
    
    defaults = [ "utf-8", "iso-8859-1" ]
    
    impossibles = defaults.select do |encoding|
      impossible = false
      begin
        scraper = Scraper.new(Nokogiri::HTML(raw.force_encoding(encoding)), self)
        title = scraper.find_title
        body = scraper.find_body
        [ title, body ].compact.each do |x|
          impossible = true unless UTF8Check::valid_utf8?(x)
        end
      rescue ArgumentError => e
        impossible = true
      end
      impossible
    end
    
    selectors =
      [
       lambda { |d| d.xpath("//meta[@http-equiv='content-type']/@content") },
       lambda { |d| d.xpath("//meta[@http-equiv='Content-type']/@content") },
       lambda { |d| d.xpath("//meta[@http-equiv='Content-Type']/@content") },
      ]
    
    announced = selectors.map{ |s| s.call(html).to_s }.detect{ |x| x.length > 0 }
    
    return (defaults - impossibles).first unless announced
    
    announced.downcase!
    
    announced = announced.split(";").select{ |x| x.include? "charset=" }[-1].split("=")[1] rescue nil
    
    return announced if announced && !impossibles.include?(announced)
    return (defaults - impossibles).first
  end
  
end
