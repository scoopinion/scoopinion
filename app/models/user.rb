# == Schema Information
# Schema version: 20110603153902
#
# Table name: users
#
#  id                  :integer         not null, primary key
#  username            :string(255)
#  login               :string(255)     not null
#  email               :string(255)     not null
#  crypted_password    :string(255)     not null
#  password_salt       :string(255)     not null
#  persistence_token   :string(255)     not null
#  single_access_token :string(255)     not null
#  created_at          :datetime
#  updated_at          :datetime
#

class User < ActiveRecord::Base
  acts_as_authentic do |c|
    %w(confirmation_of_password length_of_password length_of_password_confirmation).each do |validation|
      c.send "merge_validates_#{validation}_field_options", { :if => :validate_password? }
    end
    
    %w(format_of_email uniqueness_of_email length_of_login format_of_login uniqueness_of_login).each do |validation|
      c.send "merge_validates_#{validation}_field_options", { :if => :validate_login? }
    end
    
    c.validate_login_field = false
    c.require_password_confirmation = false
  end
    
  has_many :visits, :inverse_of => :user, :dependent => :destroy
  has_many :articles, :through => :visits
  has_many :authors, :through => :articles, :uniq => true
  has_many :tags, :through => :articles
  has_many :issues
  
  has_many :article_mailings, :dependent => :destroy
  has_many :mailed_articles, :through => :article_mailings, :source => :article

  has_many :bookmarks, :dependent => :destroy
  has_many :bookmarked_articles, :through => :bookmarks, :source => :article
  
  has_many :sites, :through => :articles, :uniq => true
  has_many :fellow_visits, :through => :articles, :source => :visits

  has_many :concealments, :dependent => :destroy

  Concealment.types.each do |concealable|
    has_many :"concealed_#{concealable.pluralize.underscore}", :through => :concealments, :source => :"concealed_#{concealable.underscore}", 
      :conditions => "concealments.concealable_type = '#{concealable.capitalize}'"
  end

  has_many :authentications, :dependent => :destroy
  
  accepts_nested_attributes_for :authentications
  
  def authentications_attributes=(options)
    options.each do |i, h|
      authentications.find_by_id(h["id"]).update_attributes(h)
    end
  end

  has_many :friendships, :dependent => :destroy
  has_many :friends, :through => :friendships, :conditions => ["friendships.user_id is not null"]
  has_many :inverse_friendships, :class_name => "Friendship", :foreign_key => "friend_id", :dependent => :destroy
  has_many :inverse_friends, :through => :inverse_friendships, :source => :user, :conditions => ["friendships.user_id is not null"]

  has_many :facebook_friendships, :dependent => :destroy
  has_many :facebook_friends, :through => :facebook_friendships, :source => :potential_user
  
  has_many :languages, :class_name => "UserLanguage", :inverse_of => :user, :dependent => :destroy, :conditions => { :blacklisted => false, :greylisted => false }
  has_many :blacklisted_languages, :class_name => "UserLanguage", :inverse_of => :user, :dependent => :destroy, :conditions => { :blacklisted => true }
  has_many :greylisted_languages, :class_name => "UserLanguage", :inverse_of => :user, :dependent => :destroy, :conditions => { :greylisted => true }
  has_many :languages_including_blacklisted, :class_name => "UserLanguage", :inverse_of => :user
  
  has_many :recommendations, :order => "created_at DESC", :dependent => :destroy

  has_many :recommended_articles, :through => :recommendations, :source => :article

  has_many :unread_recommendations, :conditions => { :state => :new }, :class_name => "Recommendation"
  
  has_many :tags, :through => :visits
  
  has_many :suggested_sites, :class_name => "Site", :foreign_key => "suggester_id"
  
  has_many :shareable_invites, :class_name => "SingleUseInvite", :foreign_key => "inviter_id", :conditions => { :state => "pending" }
  
  has_many :facebook_shares
  has_many :twitter_shares
  has_many :email_shares

  has_one :invite_request
  has_one :single_use_invite
  has_many :history_items

  has_many :site_visit_counts
  
  has_many :reader_relationships
  
  has_many :invitations
  has_many :emails
  has_many :digest_emails
  
  has_many :extension_installations, :dependent => :destroy
  
  has_many :digest_time_slots, :dependent => :destroy
  
  scope :normal, where{ anonymous == false }
  scope :with_firefox_extension, where{ id.in(ExtensionInstallation.where{ version =~ "firefox-%" }.select(:user_id)) }
  scope :without_firefox_extension, where{ id.not_in(ExtensionInstallation.where{ version =~ "firefox-%" }.select(:user_id)) }
  scope :with_chrome_extension, where{ id.in(ExtensionInstallation.where{ version =~ "chrome-%" }.where{ version !~ "chrome-0" }.select(:user_id)) }
  scope :without_chrome_extension, where{ id.not_in(ExtensionInstallation.where{ version =~ "chrome-%" }.where{ version !~ "chrome-0" }.select(:user_id)) }
  
  has_one :user_analytics_item
  
  accepts_nested_attributes_for :user_analytics_item, :update_only => true

  validates_presence_of :email, unless: :anonymous?
  
  TEAM_IDS = [1, 2, 3, 4, 5, 6, 7, 9, 27, 31, 32, 51, 53, 77, 357036]
  
  def self.sensitive_column_names
    %w(username login email crypted_password single_access_token persistence_token abingo_identity password_salt languages_updated_at friends_updated_at)
  end
  
  attr_protected User.sensitive_column_names

  attr_accessor :new_user
  
  after_save do
    if anonymous_was && !anonymous && email.present?
      self.delay(run_at: 30.minutes.from_now).maybe_send_welcome_no_addon
      UserMailer.delay.welcome_all_done(user: self) if extension_installations.exists?
    end
    
    if !anonymous && !anonymous_was && email.present?
      if extension_installed_at && !extension_installed_at_was
        if self.emails.where(message_type: "welcome_no_addon").exists?
          UserMailer.delay.addon_installed(user: self)
        else
          UserMailer.delay.welcome_all_done(user: self)
        end
      end
    end
  end
  
  after_create do
    languages.create(language: locale) if locale
    languages_including_blacklisted.create(language: "en", greylisted: true)
  end
  
  def twitter
    { 
      1 => "villesundberg",
      2 => "johanneskoponen",
      7 => "mikaelkoponen",
      27 => "kobrako"
    }[self.id]
  end
  
  def maybe_send_welcome_no_addon
    if ! extension_installed_at 
      UserMailer.welcome_no_addon(user: self)
    end
  end
  
  def create_shareable_invites
    return if shareable_invites.count >= 4
    to_create = 4 - shareable_invites.count
    to_create.times { shareable_invites.create }
  end
  
  def username=(new_username)
    super(new_username.try :strip)
  end
  
  def update_relationships
    
    unless reader_relationships_fresh?
      
      update_language_weights
      
      authors.where{ visits.created_at > 3.months.ago }.find_each(:batch_size => 100) do |a|
        last_update = ReaderRelationship.where(user_id: id, source_id: a.id, source_type: "Author").maximum(:updated_at) || Time.utc(0)
        relation = visits.joins(:article => :authors).where("authors.id" => a.id).newer_than(3.months)
        unless last_update && last_update > self.updated_at || last_update > (relation.maximum(:updated_at) || Time.utc(0))
          ReaderRelationship.update_relationship(self, a, relation)
        end
      end
      
      GC.start
      
      sites.find_each(:batch_size => 100) do |s|
        last_update = ReaderRelationship.where(user_id: id, source_id: s.id, source_type: "Site").maximum(:updated_at) || Time.utc(0)
        relation = visits.joins(:article => :site).where("sites.id" => s.id).newer_than(3.months)
        unless last_update && last_update > self.updated_at || last_update > (relation.maximum(:updated_at) || Time.utc(0))
          ReaderRelationship.update_relationship(self, s, relation)
        end
      end
      
    end

  end
  
  def weighed_feed
    update_relationships unless reader_relationships.exists?
    Article.where{average_visiting_time > 1.day.ago}.where{score > 0}.sort_by{|x| -x.weighed_score(self) }.take(10).map &:to_s
  end
  
  def self.create_anonymous(options = { })
    create({ :anonymous => true, :login => "", :email => "", :crypted_password => "", :password_salt => "" }.merge(options))
  end
  
  def self.demographics(samples)
    demo = { }
    
    [ (0..14),(15..19),(20..24),(25..29),(30..34),(35..39), (40..44), (45..49), (50..54), (55..59), (60..64), (65..69), (70..99) ].each do |age|
      
      demo[age] = { }
      
      [ "male", "female" ].each do |g|
        demo[age][g] = samples.where("birthday < ? and birthday > ?", age.min.years.ago, age.max.years.ago).where(:gender => g).count
      end
    
    end

    demo
  end
  
  def frequented_sites
    visits.includes(:article => :site).newer_than(2.months).map(&:site).uniq.select do |site|
      site.visits.where(:user_id => self.id).newer_than(2.months).sum(:total_time) > 600
    end
  end
  
  def recent_percentage(site)
    visits.newer_than(2.months).joins(:article).where("articles.site_id" => site.id).sum(:total_time).to_f / visits.newer_than(2.months).sum(:total_time)
  end
  
  def visits_to_site(site)
    visits.joins(:article).where("articles.site_id" => site.id)
  end
  
  def concealed?(article)
    concealments.where(:concealable_id => article.id, :concealable_type => "Article").exists?
  end

  def conceal(object)
    self.concealments.create(concealable_type: object.class, concealable_id: object.id)
  end
  
  def current_issue
    @current_issue ||= issues.newest_first.first
  end
  
  def normal?
    !anonymous?
  end

  
  def validate_login?
    !anonymous?
  end

  def validate_password?
    ! (authenticated? || anonymous? || (password.blank? && ! crypted_password.blank? ))
  end

  def most_frequent_sites(period)
    recent_articles = articles.where("visits.created_at > ?", Time.now - period).includes(:site).where("site_id IS NOT NULL")
    recent_articles.group_by(&:site).sort_by { |site, articles| -articles.count }
  end
  
  def mostly_reading(period)
    recent_visits = visits.where("visits.created_at > ?", Time.now - period).includes(:site)
    recent_visits.group_by(&:site).map{ |site, visits| [site, visits.inject(0){ |sum, v| v.total_time? ? (sum + v.total_time) : sum } ] }.sort_by { |site, seconds| -seconds }
  end

  def self.find_or_new_by_auth_hash_or_current_user(auth_hash, current_user, abingo_identity)
    if (authentication = Authentication.find_by_auth_hash(auth_hash))
      auth_hash_decorator = AuthHashDecorator.new(auth_hash)
      authentication.update_attributes(auth_hash_decorator.get_update_attributes)
      user = authentication.user
      user.apply_omniauth(auth_hash)
      user.new_user = false
    elsif (user = User.find_by_email(auth_hash.info.email))
      user.apply_authentication(auth_hash)
      user.new_user = false
    elsif (user = current_user)
      user.new_user = current_user.anonymous?
      user.apply_authentication(auth_hash)
    else 
      user = User.create_anonymous
      user.apply_authentication(auth_hash)
      user.set_abingo_identity(abingo_identity)
      user.new_user = true
    end
    user
  end

  def apply_authentication(auth_hash)
    auth_hash_decorator = AuthHashDecorator.new(auth_hash)
    self.authentications.build(auth_hash_decorator.get_build_attributes)
    self.apply_omniauth(auth_hash)
    self.authenticated = true
    self.anonymous = false
    self.signup_completed_at ||= Time.now if (self.created_at || Time.now) > Time.utc(2012, 10, 1)
    self.crypted_password ||= ""
    self.password_salt ||= ""
  end

  def apply_omniauth(omniauth)
      # Update user info fetching from social network
    case omniauth["provider"]
    when "facebook" then self.apply_facebook(omniauth)
    when "twitter" 
      self.apply_twitter(omniauth)
    end
  end

  def update_to_anonymous!
    self.update_attributes!({ anonymous: true, email: "" })
  end

  def facebook
    @fb_user ||= FbGraph::User.me(self.authentications.find_by_provider('facebook').token)
  end

  def as_json(options={})
    options ||= {}
    super(options.merge(:only => [:id, :languages_updated_at], :methods => [:display_name]))
  end

  def display_name
    username || login || "Anonymous"
  end
  
  def first_name
    return "user" unless display_name
    display_name.split(' ').first 
  end

  def facebook_uid
    @fb_uid ||= self.authentications.find_by_provider('facebook').try(:uid)
  end

  def profile_pic(parameters={})
    if facebook_uid
      "//graph.facebook.com/#{facebook_uid}/picture?#{parameters.to_query}"
    else 
      ""
    end
  end

  def unread_notifications
    notifications.not_by(self).unread
  end

  def activity
    notifications.where("subject_id = ? OR subject_id IS NULL", id)
  end

  def team_member?
    TEAM_IDS.include? id
  end
  
  def top_badges
    badges.reject{ |b| badges.select{ |x| x.badge_type == b.badge_type }.any? { |b2| b2.level > b.level }}
  end
  
  def guess_language(language)
    return unless language
    return if self.languages.where(:language => language).exists?
    s = sites.where(:language => language).group_by(&:id)
    if s.detect{ |s| s[1].count > 3}
      self.languages.create(:language => language)
    end
  end
    
  def guess_languages!
    visits.limit(200).includes(:article).group_by{ |x| x.article.try :language }.each do |lang, visits|
      self.languages.create(:language => lang) if visits_count > 5
    end
    return self
  end
    
  def feed_languages
    all = languages_including_blacklisted
    base = (all.select{ |x| !x.blacklisted && !x.greylisted}.map(&:language) + [ site_language ]).compact
    base = base - all.select(&:blacklisted).map(&:language)
    base << "en" if base.empty?
    return base.uniq
  end

  def site_language
    if locale
      result = locale.split("_").first
      return "en" unless I18n.available_locales.include?(result.to_sym)
      return result
    else
      return "en"
    end
  end
  
  def friend_of?(user)
    friend_cache.include? user
  end
  
  def friend_cache
    @friend_cache ||= friends + inverse_friends
  end
  
  def tag_percentages
    @tag_percentages || calculate_tag_percentages
  end
    
  def self.site_percentages(id)
    Rails.cache.fetch("site-percentage/#{id}", :expires_in => 2.days) do
      User.find(id).calculate_site_percentages
    end
  end
    
  def self.author_percentages(id)
    @author_percentages ||= { }
    @author_percentages[id] ||= Rails.cache.fetch("author-percentage-v2/#{id}", :expires_in => 2.days) do
      User.find(id).calculate_author_percentages
    end
  end
  
  def author_seconds
    @author_seconds ||=
      Author.find_by_sql([ "SELECT authors.id, sum(visits.total_time) 
                            FROM authors
                              INNER JOIN authorships ON authorships.author_id = authors.id 
                              INNER JOIN articles ON articles.id = authorships.article_id
                              INNER JOIN visits ON articles.id = visits.article_id 
                                WHERE visits.user_id = ?
                                  AND visits.referred_by_scoopinion != 't'
                                  GROUP BY authors.id 
                                    ORDER BY sum desc", id ] ).select{ |s| s.sum }
  end
  
  def site_seconds
    top_sites.map(&:sum).map(&:to_i).sort.reverse
  end
  
  def top_sites
    @site_seconds ||=
      Site.find_by_sql([ "SELECT sites.id, sum(visits.total_time) 
                            FROM sites
                              INNER JOIN articles ON articles.site_id = sites.id
                              INNER JOIN visits ON articles.id = visits.article_id 
                                WHERE visits.user_id = ?
                                  AND visits.referred_by_scoopinion != 't'
                                  GROUP BY sites.id 
                                    ORDER BY sum desc", id ] ).select{ |s| s.sum }
  end
  
  def top_site_fractions
    secs = site_seconds
    total = site_seconds.inject(:+)
    site_seconds.map{ |x| x.to_f / total }.take(10)
  end
  
  def fast_author_seconds
    @fast_author_seconds ||= Rails.cache.fetch([ "author_seconds v2", id, visits.first.created_at ]) do
      author_seconds.map(&:sum).map(&:to_i).sort.reverse
    end
  end
  
  def calculate_author_percentages
    total = visits.sum(:total_time).to_f
    return { } unless total > 0
    @author_percentages = Hash[author_seconds.map{ |t| [ t.id, t.sum.to_f / total ]}]    
  end
  
  def calculate_site_percentages
    site_minutes = Site.find_by_sql([ "SELECT sites.id, sum(visits.total_time) 
                            FROM sites 
                              INNER JOIN articles ON sites.id = articles.site_id
                              INNER JOIN visits ON articles.id = visits.article_id 
                                WHERE visits.user_id = ?
                                  AND visits.referred_by_scoopinion != 't'
                                  GROUP BY sites.id 
                                    ORDER BY sum desc", id ] ).select{ |s| s.sum }
    
    total = visits.sum(:total_time).to_f
    return { } unless total > 0
    @site_percentages = Hash[site_minutes.map{ |t| [ t.id, t.sum.to_f / total ]}]    
  end
  
  def recent_reads
    @recent_reads ||= articles.newer_than(3.months)
  end
  
  def recent_read_count
    @recent_read_count ||= recent_reads.count
  end
  
  def compatibility_with(other, options={ })
    friendships.detect{ |f| f.friend_id == other.id }.try(:compatibility, options)
  end
  
  def calculate_compatibility_with(other_id)
    other_authors = User.author_percentages(other_id)
    shared_authors = User.author_percentages(id).map do |key, value|
      [ value, (other_authors[key] || 0) ].min
    end
    [ 100, shared_authors.inject{ |sum, n| sum + n} || 0 ].min
  end
  
  def calculate_tag_percentages
    tag_minutes = Tag.find_by_sql([ "SELECT tags.id, sum(visits.total_time) 
                            FROM tags 
                              INNER JOIN article_tags ON tags.id = article_tags.tag_id
                              INNER JOIN articles ON article_tags.article_id = articles.id 
                              INNER JOIN visits ON articles.id = visits.article_id 
                                WHERE visits.user_id = ?
                                  GROUP BY tags.id 
                                    ORDER BY sum desc", id ] ).select{ |s| s.sum }
    
    total = visits.sum(:total_time).to_f
    @tag_percentages = Hash[tag_minutes.map{ |t| [ t.id, t.sum.to_f / total ]}]
  end
    
  def active_app?
    ! extension_installed_at.blank? && newest_visit && newest_visit > 7.days.ago
  end
  
  def prepare_visited(articles)
    @visited_articles = visits.where{ article_id.in(articles.map(&:id)) }.group_by(&:article_id)
    @visited_prepared = true
  end
  
  def visited?(article)
    @visited_articles ||= { }
    return @visited_articles[article.id] if @visited_articles[article.id] || @visited_prepared
    return false unless newest_visit
    return false unless article.created_at
    return false if newest_visit < article.created_at
    return visits.where(:article_id => article.id).exists?
  end

  def visited_urls=(urls)
    urls.each do |site_url, arr|
      arr.each { |url| history_items.create(:url => url)}
    end
    self.delay.process_history_items
  end  
  
  def visited_sites=(sites)
    sites.each do |site_url, count|
      site = Site.find_by_full_url(site_url)
      svc = SiteVisitCount.find_or_initialize_by_site_id_and_user_id(site.id, id)
      svc.count = count
      svc.save
    end
  end
  
  def process_history_items
    history_items.each{ |h| h.delay.process }
  end

  def newest_visit
    @newest_visit ||= Rails.cache.fetch(["User#newest_visit", self, "v3"]) do
      visits.maximum(:created_at)
    end
  end
  
  def update_profile_page_cache
    Profile.generate(:user => self)
  end
  
  def most_frequent_sites_in_browser_history(options = {})
    options = { :period => 100.years, :limit => 10 }.merge options
    Site.find_by_sql([ "SELECT sites.id, count(visits)
                            FROM sites 
                              INNER JOIN articles ON articles.site_id = sites.id
                              INNER JOIN visits ON articles.id = visits.article_id 
                                WHERE visits.user_id = ? and visits.created_at > ? and visits.history_item_id is not null
                                  GROUP BY sites.id 
                                    ORDER BY count desc", id, Time.now - options[:period] ]
                             ).select{ |x| x.count }.first(options[:limit]).map{ |x| [ Site.find(x.id), x.count.to_i ]}
  end
  
  def most_frequent_conglomerates(options = {})
    options = { :period => 100.years, :limit => 10 }.merge options
    Site.find_by_sql([ "SELECT conglomerates.id, count(visits)
                            FROM conglomerates
                              INNER JOIN sites ON sites.conglomerate_id = conglomerates.id 
                              INNER JOIN articles ON articles.site_id = sites.id
                              INNER JOIN visits ON articles.id = visits.article_id 
                                WHERE visits.user_id = ? and visits.created_at > ?
                                  GROUP BY conglomerates.id 
                                    ORDER BY count desc", id, Time.now - options[:period] ]
                             ).select{ |x| x.count }.first(options[:limit]).map{ |x| [ Conglomerate.find(x.id), x.count.to_i ]}
  end
  
  def most_frequent_conglomerates_by_time(options = {})
    options = { :period => 100.years, :limit => 10 }.merge options
    Site.find_by_sql([ "SELECT conglomerates.id, sum(visits.total_time)
                            FROM conglomerates
                              INNER JOIN sites ON sites.conglomerate_id = conglomerates.id 
                              INNER JOIN articles ON articles.site_id = sites.id
                              INNER JOIN visits ON articles.id = visits.article_id 
                                WHERE visits.user_id = ? and visits.created_at > ?
                                  GROUP BY conglomerates.id 
                                    ORDER BY sum desc", id, Time.now - options[:period] ]
                             ).select{ |x| x.sum }.first(options[:limit]).map{ |x| [ Conglomerate.find(x.id), x.sum.to_i ]}
  end

  def most_frequent_authors_in_browser_history(options = {})
    options = { :period => 100.years, :limit => 20 }.merge options
    Author.find_by_sql([ "SELECT authors.id, count(visits)
                            FROM authors 
                              INNER JOIN authorships ON authors.id = authorships.author_id 
                              INNER JOIN articles ON authorships.article_id = articles.id 
                              INNER JOIN visits ON articles.id = visits.article_id 
                                WHERE visits.user_id = ? and visits.created_at > ? and visits.history_item_id is not null
                                  GROUP BY authors.id 
                                    ORDER BY count desc", id, Time.now - options[:period] ]
                                 ).select{ |x| x.count }.first(options[:limit]).map{ |a| [ Author.find(a.id), a.count.to_i ]}
  end

  def most_frequent_authors(options = {})
    options = { :period => 100.years, :limit => 10 }.merge options
    Author.find_by_sql([ "SELECT authors.id, sum(visits.total_time) 
                            FROM authors 
                              INNER JOIN authorships ON authors.id = authorships.author_id 
                              INNER JOIN articles ON authorships.article_id = articles.id 
                              INNER JOIN visits ON articles.id = visits.article_id 
                                WHERE visits.user_id = ? and visits.created_at > ? 
                                  GROUP BY authors.id 
                                    ORDER BY sum desc", id, Time.now - options[:period] ]
                                 ).select{ |x| x.sum }.first(options[:limit]).map{ |a| [ Author.find(a.id), a.sum.to_i ]}
  end
  
  def most_frequent_tags(options = {})
    options = { :period => 100.years, :limit => 10 }.merge options
    Tag.find_by_sql([ "SELECT tags.id, sum(visits.total_time) 
                            FROM tags 
                              INNER JOIN article_tags ON tags.id = article_tags.tag_id
                              INNER JOIN articles ON article_tags.article_id = articles.id 
                              INNER JOIN visits ON articles.id = visits.article_id 
                                WHERE visits.user_id = ? and visits.created_at > ? 
                                  GROUP BY tags.id 
                                    ORDER BY sum desc", id, Time.now - options[:period] ]
                       ).select{ |x| x.sum }.first(options[:limit]).map{ |a| [ Tag.find(a.id), a.sum.to_i ]}
  end
  
  def self.digest_list
    User.normal.where{ (signup_completed_at == nil) | (signup_completed_at < 3.days.ago) }.where(:unsubscribed => false).order("id asc")    
  end
  
  def self.schedule_digests
    Delayed::Job.transaction do
      digest_list.find_each{ |x| x.delay.schedule_digest }
    end
    return digest_list.count
  end
  
  def schedule_digest
    self.delay( run_at: self.digest_sending_time ).send_digest
  end
  
  def params
    { }
  end
  
  def send_digest(options={ })
    
    if digest_emails.exists? && digest_emails.maximum(:created_at) > 24.hours.ago && !options[:force]
      return false
    end
    
    Feeds::Digest.new(user: self, languages: feed_languages).articles.tap do |articles|
      if articles.any?        
        DigestEmail.transaction do
          NewDigestMailer.digest(:user => self, :articles => articles)
        end
      end
    end
  end
  
  def self.send_activation_pings
    User.normal.where{ (unsubscribed == false) & (extension_installed_at != nil) & (updated_at < 3.weeks.ago) }.where{ id.not_in(Email.where(message_type: "activation_ping").select(:user_id)) }
      .select{|x| !x.visits.exists? || x.visits.maximum(:created_at) < 3.weeks.ago }.select{ |x| x.emails.maximum(:created_at) < 1.day.ago rescue true }.reject{|x| x.article_mailings.newer_than(3.weeks).where{ clicked_at != nil }.exists? }.map do |user|
      UserMailer.delay.activation_ping(user: user)
    end
  end
  
  def favorite_authors
    self.delay.update_relationships unless reader_relationships_fresh?
    reader_relationships.where(:source_type => "Author").order("favoritism desc").includes(:source).limit(12).map(&:source)
  end
  
  def reader_relationships_fresh?
    return false unless reader_relationships.exists?
    return true unless visits.exists?
    reader_relationships.maximum(:updated_at).tap do |update_max|
      return true if update_max > visits.maximum(:created_at)
      return true if update_max < 12.hours.ago
    end
    false
  end 

  def self.find_by_login_or_email(login)
    normal.find_by_email(login) || normal.find_by_login(login)
  end
  
  def weekly_reading_pattern
    visits.where{ total_time != nil }.where{ total_time < 1800 }.group_by{ |x| x.created_at.wday * 24 + x.created_at.hour }.map{ |x,y| [x, y.map(&:total_time).sum ]}
  end
  
  def weekly_reading_time
    visits.where{ total_time != nil }.where{ total_time < 1800 }.group_by{ |x| x.created_at.yday / 7 }.map{ |x,y| [x, y.map(&:total_time).sum / 60 ]}
  end
  
  def weekly_read_through
    visits.joins(:article).where{ article.word_count != nil}.where{ total_time != nil }.where{ total_time < 1800 }.group_by{ |x| x.created_at.yday / 7 }.map{ |x,y| r = y.map{ |x| (100 * x.words_read / x.article.word_count.to_f).to_i }; [x, r.inject(:+) / r.count ] } 
  end
  
  def weekly_languages
    visits.where{ total_time != nil }.where{ total_time < 1800 }.includes(:article).group_by{ |x| x.article.try :language }.select{ |x,y| feed_languages.include? x }.map{ |x, y| [ x, y.group_by{ |x| x.created_at.yday / 7 }.map{ |x, y| [ x, y.map(&:total_time).sum ] } ] }
  end
  
  def invites_left
    [ 0, (5 - invitations.count)].max
  end
  
  def update_language_weights
    total_times = feed_languages.map do |code|
      [ code, visits.newer_than(6.months).joins(:article).where{ article.language == code }.sum(:total_time) ]
    end
    total = total_times.inject(0){ |sum,x| x[1] + sum }
    return unless total > 0
    weights = total_times.map { |x| [ x[0], x[1] / total.to_f ]}
    weights.each do |p|
      languages_including_blacklisted.update_all({ weight: p[1] }, { language: p[0] })
    end
  end
  
  def maybe_renew_issue_later
    return nil unless visits.first
    
    reading_fraction = average_activity_by_hour(scpn_only: true)[:percent]
    
    case reading_fraction
    when 0
      refreshes = 1
    else
      refreshes = 2
    end
    
    slice = 60 / refreshes
    
    (1..refreshes).map do |i|
      delay(:priority => 2, :run_at => (((i-1) * slice) + Random.rand(slice / 2)).minutes.from_now).renew_issue 
    end
  end
  
  def renew_issue
    issue = Issue.new(user_id: id)
    issue.generate!
    issue
  end
  
  def maybe_remind_about_invites
  end
  
  def invitation_suggestions
    require "enumerable"
    friends = facebook_friends.order("friends_count desc").where{ friends_count != nil }.limit(20)
    probable_users = User.normal.where{ username.in(friends.pluck(:name))}.group_by{ |x| x.username }
    friends.take_selecting(7){ |x| !probable_users[x.name] }
  end
  
  def init_abingo
    self.abingo_identity ||= rand(10 ** 10).to_i.to_s
    save if self.abingo_identity_changed?
    self.abingo_identity
  end

  def set_abingo_identity(identity)
    identity ||= rand(10 ** 10).to_i.to_s
    self.abingo_identity = identity
  end

  def has_access_to_service(service)
    authentications.where{ provider == service }.any?
  end
  
  def send_data_dump
    data_url = dump_data
    UserMailer.your_data_is_ready(:user => self, :download_url => data_url)
  end
  
  def dump_data(limit=nil)
    JSONSerializer.dump(self, limit)
  end
  
  def top_sites_by_time(options)
    percent = options[:percentile]
    list = site_seconds
    return 0 if list.count == 0
    list.take(list.count * (percent / 100.0)).inject(:+).to_f / list.inject(:+)     
  end
  
  def top_authors_by_time(options)
    percent = options[:percentile]
    list = fast_author_seconds
    return 0 if list.count == 0
    list.take(list.count * (percent / 100.0)).inject(:+).to_f / list.inject(:+) 
  end

  def build_twitter_share(attributes = {})
    twitter_share = self.twitter_shares.build(attributes)
    twitter_share.authentication = authentications.where{provider == "twitter"}.first
    twitter_share
  end

  def social_shares
    twitter_shares + facebook_shares + email_shares
  end
  
  def average_activity_by_hour(options = { })
    hour = options[:hour] || Time.now.getutc.hour
    visiting_hours(options).detect{ |x| x[:hour] == hour }
  end
  
  def visiting_hours(options = { })
    Rails.cache.fetch(:expires_in => 1.week) do
      wday = options[:wday]
      scpn_only = options[:scpn_only]
      
      relation = visits.newer_than(1.month)
      relation = relation.where("date_part('dow', created_at) = '#{wday}'") if wday
      relation = relation.solicited if scpn_only
      
      total = relation.sum(:total_time)
      hours = relation.group_by{ |x| x.created_at.hour }.map do |x,y| 
        sum = y.map(&:total_time).compact.sum 
        { :hour => x, :count => y.count, :time => sum, :percent => (sum * 100.0 / total).round(1) }
      end
      
      (0..23).each do |h|
        unless hours.any?{ |x| x[:hour] == h }
          hours << { :hour => h, :count => 0, :time => 0, :percent => 0 }
        end
      end
      
      hours.sort_by!{ |x| x[:hour]}
      hours
    end
  end
  
  def most_frequent_hour(options = { })
    v = visiting_hours(options)
    return nil unless v && v.size > 0
    v.sort_by{ |x| x[:time] }.last[:hour]
  end
  
  def digest_sending_time
    if visits_count < 50
      hour = 11
    else
      hour = most_frequent_hour(:wday => Time.now.utc.wday) || most_frequent_hour
    end
    
    random_factor = Random.rand(60) - 30
    before_factor = -120
    
    Time.now.utc.change(:hour => hour) + (random_factor + before_factor).minutes
  end
    
  def activate_profile_beta!
    key = "profile_page_beta_ids"
    group = JsonCache.read("profile_page_beta_ids")
    group << self.id
    JsonCache.write(key, group)
  end
  
  def active_in_period?(time_start, time_end)
    beginning = visits.where{ created_at > time_start }.where{ created_at < time_start + 1.week }
    ending = visits.where{ created_at > time_end - 1.week }.where{ created_at < time_end }
    total = visits.where{ created_at > time_start }.where{ created_at < time_end }
    
    beginning.exists? && ending.exists? && total.count >= (time_start - time_end) / 1.day
  end
  
  scope :sent, Proc.new{ |email| where{ id.in(Email.where(message_type: email).select(:user_id))} }
  scope :not_sent, Proc.new{ |email| where{ id.not_in(Email.where(message_type: email).select(:user_id))} }
  
  def send_fingerprint_launch(options = { })
    precalculate_profile!
    
    return false if emails.where(message_type: "fingerprint_launch").exists? && !options[:force]
  
    Email.transaction do
      UserMailer.fingerprint_launch(:user => self)
    end
  end
  
  def precalculate_profile!
    Profile.by_site(user: self, mode: "worker")
  end
  
  def self.send_fingerprint_interesting_emails
    Delayed::Job.transaction do
      User.normal.not_sent("fingerprint_launch").not_sent("fingerprint_interesting").where{ visits_count > 50 }.select{ |x| x.site_language == "en" }.each do |u|
        u.delay.send_fingerprint_interesting
      end
    end
  end
  
  def send_fingerprint_interesting(options = { })
    
    return false if site_language != "en"
    
    Abingo.identity = init_abingo
    ab_test("fingerprint_interesting_clickthrough", [true], :conversion => "link_fpint")
    
    precalculate_profile!
    
    if !options[:force]
      if [ emails.where(message_type: "fingerprint_launch"),
           emails.where(message_type: "fingerprint_interesting"),
           emails.where{ unsubscribed_at != nil } ].any?(&:exists?)
        return false 
      end
    end
    
    Email.transaction do
      UserMailer.fingerprint_interesting(:user => self)
    end
  end
  
  def subscribed
    !unsubscribed
  end
  
  def subscribed=(bool)
    self.unsubscribed = bool
    self.unsubscribed = !unsubscribed
  end
  
    
  def self.chrome_web_store_migration_email_recipients
    User.where{ id.in(Visit.unsolicited.where{ user_id.in(User.normal.without_chrome_extension.without_firefox_extension.select(:id)) }.select("distinct user_id")) }.where{ id.not_in(Email.unsubscribed.select(:user_id)) }
  end
  
  def self.schedule_chrome_web_store_migration_emails
    Delayed::Job.transaction do
      chrome_web_store_migration_email_recipients.each{ |u| u.delay.send_chrome_web_store_migration_email }
    end
  end
  
  def send_chrome_web_store_migration_email(options = { })
    Abingo.identity = init_abingo
    ab_test("chrome_web_store_migration_clickthrough", [true], :conversion => "link_cws_migration")
    
    if !options[:force]
      if emails.where{ unsubscribed_at != nil }.exists? ||
          emails.where{ message_type == "chrome_web_store_migration" }.exists?
        return false 
      end
    end
    
    Email.transaction do
      UserMailer.launch(:user => self)
    end

  end
  
  def self.recent_contributor_ids
    Visit.newer_than(1.week).select("distinct user_id").pluck(:user_id)
  end

  def has_bookmarked?(article)
    bookmarked_articles.include?(article)
  end
  
  def email=(new_email)
    self[:email] = new_email.try :downcase
  end
  
  def extension=(new_extension)
    self.extension_installed_at ||= Time.now
    if new_extension.to_s["-"] # chrome-0.47.8, firefox-0.7 etc
      self.extension_installations.find_or_create_by_version(new_extension).tap do |installation|
        installation.touch
      end
    end
  end
  
  def languages=(new_languages)
    new_languages.keys.
      reject{ |lang| self.languages_including_blacklisted.where(:language => lang).exists? }.
      map { |lang| self.languages.create(:language => lang) }
    
    self.languages.where(language: new_languages.keys).each(&:touch)
    self.greylisted_languages.where(language: new_languages.keys).update_all(greylisted: false)
    self.languages.where("updated_at < ?", 2.months.ago).delete_all
    
    update_attributes(:languages_updated_at => Time.now)
  end
  
  def neighbors
    UserCompatibility.user(self.id).where{ user_a_id != user_b_id }.order("compatibility desc").limit(100).includes(:user_a).includes(:user_b).map{ |x| x.other(self.id) }
  end
  
  protected

  def apply_facebook(omniauth)
    self.email = email.presence || omniauth['info']['email']
    self.login = login.presence || omniauth['info']['email']
    # fetch extra user info from facebook
    self.username = omniauth['info']['name']
    if (extra = omniauth['extra']['raw_info'] rescue false)
      self.gender = extra.try(:[], 'gender') or self.gender
      self.locale = extra.try(:[], 'locale') or self.locale
      self.location = extra.try(:[], 'location').try(:[], 'name') or self.location
      self.hometown = extra.try(:[], 'hometown').try(:[], 'name') or self.hometown
      new_birthday = Date.strptime(extra['birthday'], '%m/%d/%Y') rescue nil
      self.birthday = new_birthday || self.birthday
    end
    delay.save_facebook_friends
  end

  def apply_twitter(omniauth)
    self.username = username.presence || omniauth["info"]["name"]
  end

  def save_facebook_friends
    friends = facebook.friends
    
    existing_users = User.normal.includes(:authentications).where("authentications.uid in (?)", friends.map(&:identifier))
    
    existing_users.each do |user|
      unless friend_of?(user)
        Friendship.make_friends(self, user)
      end
    end
    
    existing_uids = existing_users.map(&:authentications).flatten.map{ |a| a.uid }
    
    filtered_facebook_friends = friends.reject{ |f| existing_uids.include? f.identifier }

    save_potential_users(filtered_facebook_friends)

    self.touch(:friends_updated_at)
  end

  def save_potential_users(filtered_facebook_friends)
    filtered_facebook_friends.each do |friend|
      potential = PotentialUser.find_or_initialize_by_uid(friend.identifier)
      potential.update_attributes({:name => friend.name, :uid => friend.identifier})
      FacebookFriendship.find_or_create_by_user_id_and_potential_user_id(:user_id => self.id, :potential_user_id => potential.id) rescue nil
    end
  end
    
end
