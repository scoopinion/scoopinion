# == Schema Information
# Schema version: 20110603153902
#
# Table name: sites
#
#  id         :integer         not null, primary key
#  url        :string(255)
#  name      :string(255)
#  created_at :datetime
#  updated_at :datetime
#

require 'transitions'

class Site < ActiveRecord::Base

  include ActiveRecord::Transitions

  validates :name, {
    :presence => true,
    :length => {:minimum => 1}
  }

  validates :url, {
    :presence => true,
    :uniqueness => true,
    :length => {:minimum => 1}
  }
  
  has_many :sections
  has_many :articles
  has_many :authors, :through => :articles
  has_many :visits, :through => :articles
  has_many :readers, :through => :visits, :source => :user, :select => :id
  has_many :scraping_rules
  has_many :rss_feeds
  
  include Concealable
  
  has_many :recent_readers, :through => :visits, :source => :user, :select => :id, :uniq => true, :conditions => [ "visits.created_at > ?", 1.month.ago ]
  
  has_many :alternate_names
  
  belongs_to :suggester, :class_name => "User"
  belongs_to :conglomerate
  
  before_validation do
    state ||= "suggested"
    normalize_url if state == "suggested"
  end
  
  state_machine do
    state :suggested
    state :confirmed
    state :rejected
  end

  scope :confirmed, where("state = 'confirmed'")
  scope :suggested, where("state = 'suggested'")
  scope :rejected, where("state = 'rejected'")
  
  def scraping_status
    recent_articles = articles.newer_than(1.month)
    total = recent_articles.count.to_f
    { 
      suitable: recent_articles.where{ suitable }.count / total, 
      score: recent_articles.where{ score > 0 }.count / total,
      recent_articles: total.to_i
    }
  end
  
  def self.find(q)
    unless a = where("lower(name) = ?", q.to_s.gsub("-", " ")).first
      return super
    end
    return a
  end
  
  def self.find_by_name(name)
    super || AlternateName.find_by_name(name).try(:site)
  end
  
  def title
    name
  end
  
  def display_name
    name
  end
  
  def profile_pic(options={ })
    if twitter && !Rails.env.development?
      Rails.cache.fetch([self, "profile_pic", "v3"]) do
        Tweeter.configure_twitter!
        Twitter.user(twitter).profile_image_url_https.gsub("_normal", "")
      end
    end
  end
  
  def primary_site
    nil
  end
    
  def self.process_csv(file)
    require 'csv'
    data = CSV.read(file, :col_sep => ";")
    data.reject! { |a| ! a[1] || ! a[1].start_with?("http") }
    data.map{ |a| a.map{ |c| c.strip! } }
    sites = data.map do |a|
      Site.new do |s|
        s.name = a[0]
        s.url = a[1]
        s.language = a[2]
      end
    end
    
    sites.each do |s|
      s.normalize_url(:retain_www => true)
      p s.name + " " + s.url
      p s.guess_language
    end
  end
  
  def self.add_from_csv(string)
    require 'csv'
    raw = CSV.parse(string)
    raw.reject! { |a| not a[1] }
    raw.each{ |a| a[0] = a[0][0..-2] }
    
    raw.each do |name, url|
      next if self.find_by_full_url(url)
      site = Site.new(:name => name, :url => url, :state => "confirmed")
      site.normalize_url(:retain_www => true)
      site.save
      p site
    end
  end
  
  def owners
    conglomerate.try :all_owners
  end
  
  def self.host(url)
    cleansed_url = url.gsub(/#.*$/, "")
    cleansed_url.gsub!(/\?.*$/, "")
    cleansed_url.gsub!(/^.*?:\/\//, "")
    cleansed_url.gsub!(/\/.*/, "")
    cleansed_url
  end
  
  def self.find_by_full_url(url)
    cleansed_url = host(url)
    server = cleansed_url
    server_parts = server.split(".")

    site_url = server_parts.pop

    server_parts.reverse.each do |part|
      site_url = "#{part}.#{site_url}"
      site = Site.confirmed.where("url = ?", site_url).first
      return site if site && !site.blacklisted?(url)
    end

    return nil
  end
  
  def cached_recent_readers
    @recent_readers ||= self.recent_readers.all
  end
  
  def relatedness_to(other)
    
    relatedness_object = SiteRelatedness.find_or_create_by_source_id_and_target_id(self.id, other.id)
    reverse_object = relatedness_object.reverse_object
    
    if self.visits.newer_than(1.month).count == 0 || other.visits.newer_than(1.month).count == 0
      relatedness_object.relatedness = relatedness_object.reverse = relatedness_object.mutual = 0
      reverse_object.relatedness = reverse_object.reverse = reverse_object.mutual = 0
      relatedness_object.save
      reverse_object.save
      return relatedness_object
    end
    
    common_readers = (self.cached_recent_readers & other.cached_recent_readers).uniq
    common_seconds = common_readers.inject(0) do |sum, user|
      sum + [ user.visits_to_site(self).newer_than(1.month).sum(:total_time), user.visits_to_site(other).newer_than(1.month).sum(:total_time) ].min
    end
    
    newest_visits_sum = visits.newer_than(1.month).sum(:total_time)
    
    if newest_visits_sum > 0
      relatedness_object.relatedness = common_seconds.to_f / newest_visits_sum
    end
    
    other_newest_visits_sum = other.visits.newer_than(1.month).sum(:total_time)
    
    if other_newest_visits_sum > 0
      reverse_object.relatedness = common_seconds.to_f / other_newest_visits_sum
    end
    
    relatedness_object.relatedness ||= 0
    reverse_object.relatedness ||= 0
    
    relatedness_object.reverse = reverse_object.relatedness
    reverse_object.reverse = relatedness_object.relatedness
    
    relatedness_object.mutual = reverse_object.mutual = [ relatedness_object.relatedness, reverse_object.relatedness ].min
    
    reverse_object.save
    relatedness_object.save
    relatedness_object
  end
  
  def blacklisted?(url)
    sections.detect{ |s| s.include? url }.try(:blacklisted?)
  end
  
  def as_json(options={})
    {
      :url => url,
      :name => name,
      :language => language
    }
  end
  
  def <=>(other)
    sortable_name <=> other.sortable_name
  end
  
  def sortable_name
    name.downcase.gsub("the ","").gsub(/[^a-z0-9 ]/, "") rescue "?"
  end
  
  def initial
    return '?' if name.blank?
    name.downcase.gsub("the ","").gsub(/[^a-z0-9]/, "").slice(0).chr.upcase rescue "?"
  end
  
  def guess_language!
    guess_language
    save
  end
  
  def guess_language
    @@d ||= LanguageDetector.new
    body = self.stripped_body
    if body.length > 10
      self.language = @@d.detect(body)
    end
    return self.language
  end
  
  def stripped_body
    require 'open-uri'
    open("http://" + url).read.gsub("\n", " ").gsub("\t","").gsub("\r", "").gsub(/<script.*?>.*?<\/script>/, "").gsub(/<style.*?>.*?<\/style>/, "").gsub(/<\/?[^>]*>/, "") rescue ""
  end
  
  def normalize_url(options={ })
    u = self.url or return
    u.gsub! /^http:\/\//, ""
    u.gsub! /www\./, "" unless options[:retain_www]
    u.gsub! /^[.\/]*/, ""
    u.gsub! /[.\/]*$/, ""
    url = u
  end
  
  def to_param
    "#{id}-#{name.parameterize}"
  end
  
  def to_s
    name
  end
  
  def scraping_rules_hash
    Hash[scraping_rules.group_by(&:element_type).map{ |x,y| [ x, y.map(&:rule) ]}]
  end
  
  def rescrape_all_articles
    articles.find_in_batches(:batch_size => 100) do |a|
      Delayed::Job.transaction do
        a.each { |x| x.delay(:priority => 2).scrape }
      end
    end
  end
  
  def rescrape_recent_articles
    articles.where{ average_visiting_time > 1.day.ago }.each do |x|
      Delayed::Job.transaction do
        x.delay(:priority => 2).scrape
      end
    end
  end
  
  def calculate_relatednesses
    comp = self.id
    Site.where{ id > comp }.each do |other|
      self.relatedness_to(other)
    end
  end
  
  def favoritism_for(user)
    0
  end
  
  def average_time
    Rails.cache.fetch([self, :average_time], :expires_in => 1.second) do
      a = articles.newer_than(1.week).order("random()").limit(100)
      Visit.where{ article_id.in(a) }.average(:total_time)
    end
  end
  
  def average_word_count
    articles.newer_than(4.months).average(:word_count).to_i    
  end
  
  def readthrough
    Rails.cache.fetch([self, :readthrough], :expires_in => 1.week) do
      articles.order("created_at desc").limit(50).map(&:readthrough).compact.tap{|a| a[0] = a.inject(:+) / a.size.to_f}[0] * 100
    end
  end
  
  def clicks_per_article
    articles.newer_than(3.months).average(:visits_count).to_f.round(2)
  end
  
  def ms_per_word
    (1000 * average_time / average_word_count.to_f).to_i
  end
    
  def bounce_rate
    visits.newer_than(3.months).where{ total_time != nil }.instance_eval{ where{ total_time < 10 }.count.to_f / count } 
  end

  def create_master_rss_feed!
    feeds = detect_rss_feed_urls
    
    case feeds.count
    when 0
      return nil
    when 1
      feed = feeds.first
      if RssFeed.check(feed)
        return rss_feeds.create(url: feed)
      end      
    else
      return feeds.map{ |x| puts "Site.find(#{id}).rss_feeds.create(url: \"#{x}\")"; [x] + RssFeed.urls(x).sort }
    end
  end
    
  def detect_rss_feed_urls
    page = retrieve_front_page
    return [] unless page
    doc = Nokogiri::HTML(page)
    result_count = doc.css("link[rel=alternate]").count
    return [] if result_count.zero?
    results = Array.wrap(doc.css("link[rel=alternate]")).map{ |x| x.attr("href") }
    results.map! do |x|
      if x =~ /^http/
        x
      elsif x =~ /^\//
        front_page_url + x
      else
        front_page_url + "/" + x
      end
    end
  end

  def front_page_url
    if url =~ /^www\./
      return "http://#{url}"
    else
      return "http://www.#{url}"
    end
  end
  
  def retrieve_front_page
    begin
      Timeout::timeout(200) do
        stream = open(front_page_url)

        if stream.content_encoding.empty?
          raw = stream.read
        else
          raw = Zlib::GzipReader.new(stream).read
        end
        encoding = EncodingDetector.detect(raw)
        return raw.force_encoding(encoding).encode("utf-8")        
      end
    rescue Exception => e
      ap e
      ap e.backtrace
      return false
    end
  end
  
  def related_sites
    recent_readers.map{ |x| x.articles.newer_than(3.months) }.flatten.map{ |x| x.site }
  end
  
  def popularity
    @popularity ||= Rails.cache.fetch([ self, "popularity15" ]) { 1.0 / [ 100, (visits.newer_than(2.day).count + 1) ].max } / 100.0
  end
  
  def precalculate_profile!
    Profile.clear_cache(:user => self, :mode => "worker")
    Profile.by_site(:user => self, :mode => "worker")
    touch
  end
  
  def fingerprint_key
    Digest::MD5.hexdigest([ self.id, self.class.name, "1290328923980239823092309" ].inspect)[0..5]
  end
  
  def profile_path
    "s-#{id}/#{fingerprint_key}"
  end
  
  def twitter_byline
    return "@#{twitter}" if twitter
    name.strip
  end
  
  def visits_count
    @visits_count ||= Rails.cache.fetch([ self.id, self.class.name, "visits_count" ], :expires_in => 1.week) do
      visits.newer_than(3.months).count
    end
  end
  
  def self.time_spent_lookup_table
    @time_spent_lookup ||= Rails.cache.fetch("site-lookup-table", :expires_in => 1.day) do
      self.make_time_spent_lookup_table
    end
  end
  
  def self.make_time_spent_lookup_table
    Hash[
         Visit
           .newer_than(3.months)
           .joins(:article)
           .where{ total_time < 1000 }
           .group("articles.site_id")
           .select([ "articles.site_id", "sum(total_time)" ])
           .map{ |x| [ x.site_id.to_i, x.sum.to_i ] }
        ] 
  end
  
  def self.warmup_time_spent_cache
    @time_spent_lookup = self.make_time_spent_lookup_table
    Rails.cache.write("site-lookup-table", @time_spent_lookup, :expires_in => 1.day)
    @time_spent_lookup.count
  end
  
  def self.time_spent(id)
    time_spent = time_spent_lookup_table[id]
    return time_spent unless time_spent.nil?
    
    time_spent = Visit.newer_than(3.months).joins(:article).where{ articles.site_id == id}.where{ total_time < 1000 }.sum(:total_time)
    time_spent_lookup_table[id] = time_spent
    
    time_spent
  end
  
end

