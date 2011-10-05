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
    c.merge_validates_confirmation_of_password_field_options({:unless => :authenticated?})
    c.merge_validates_length_of_password_field_options({:unless => :authenticated?})
    c.merge_validates_length_of_password_confirmation_field_options({:unless => :authenticated?})
  end

  validates_presence_of :login

  has_many :visits, :order => "created_at desc", :inverse_of => :user, :dependent => :destroy
  has_many :articles, :through => :visits, :order => "created_at desc"
  has_many :sites, :through => :articles
  has_many :fellow_visits, :through => :articles, :source => :visits
  has_many :comments, :inverse_of => :user, :dependent => :destroy

  has_many :concealments, :class_name => "ArticleConcealment", :inverse_of => :user, :dependent => :destroy
  has_many :concealed_articles, :through => :concealments, :source => :article
  
  has_many :tag_concealments, :dependent => :destroy
  has_many :concealed_tags, :through => :tag_concealments, :source => :tag
  
  has_many :authentications, :dependent => :destroy

  has_many :notifications, :order => "created_at DESC", :dependent => :destroy

  has_many :friendships, :dependent => :destroy
  has_many :friends, :through => :friendships
  has_many :inverse_friendships, :class_name => "Friendship", :foreign_key => "friend_id", :dependent => :destroy
  has_many :inverse_friends, :through => :inverse_friendships, :source => :user
  
  has_many :languages, :class_name => "UserLanguage", :inverse_of => :user, :dependent => :destroy
  
  has_many :badges, :order => "created_at DESC", :dependent => :destroy
  
  has_many :recommendations, :order => "created_at DESC", :dependent => :destroy

  has_many :recommended_articles, :through => :recommendations, :source => :article

  has_many :unread_recommendations, :conditions => { :state => :new }, :class_name => "Recommendation"
  
  has_many :tags, :through => :visits
  
  after_create do
    UserMailer.welcome(self)
  end
    
  TEAM_IDS = [1, 2, 3, 4, 5, 6, 7, 9, 27, 31, 32, 51, 53, 77]

  def concealed?(article)
    concealments.where(:article_id => article.id).any?
  end

  def authenticated?
    self.authentications.any?
  end

  def most_frequent_sites(period)
    recent_articles = articles.where("visits.created_at > ?", Time.now - period).includes(:site).where("site_id IS NOT NULL")
    recent_articles.group_by(&:site).sort_by { |site, articles| -articles.count }
  end
  
  def mostly_reading(period)
    recent_visits = visits.where("created_at > ?", Time.now - period).includes(:site)
    recent_visits.group_by(&:site).map{ |site, visits| [site, visits.inject(0){ |sum, v| v.total_time? ? (sum + v.total_time) : sum } ] }.sort_by { |site, seconds| -seconds }
  end

  def apply_omniauth(omniauth)
    self.email ||= omniauth['user_info']['email']
    self.login ||= omniauth['user_info']['email']

      # Update user info fetching from social network
    case omniauth['provider']
      when 'facebook'
        # fetch extra user info from facebook
        self.username ||= omniauth['user_info']['name']
      when 'twitter'
        # fetch extra user info from twitter
    end
  end

  def as_json(options={})
    options ||= {}
    super(options.merge(:only => [:id], :methods => [:display_name]))
  end

  def display_name
    username || login
  end

  def profile_pic(parameters = '')
    if self.authenticated?
      'http://graph.facebook.com/'+self.authentications.find_by_provider('facebook').uid+'/picture'+parameters
    else
      ''
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
    badges.reject{ |b| badges.where(:badge_type => b.badge_type).any? { |b2| b2.level > b.level }}
  end
  
  def guess_language(language)
    return unless language
    return if self.languages.where(:language => language).any?
    s = sites.where(:language => language).group_by(&:id)
    if s.detect{ |s| s[1].count > 3}
      self.languages.create(:language => language)
    end
  end
  
  def guess_languages!
    sites.group_by(&:language).each { |x| guess_language(x[0])}
  end
  
  def feed_languages
    return languages.map{ |l| l.language }
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
  
  def compatibility_with(other, options={ })
    friendships.where(:friend_id => other.id).first.try(:compatibility, options)
  end
  
  def calculate_compatibility_with(other)
    other_tags = other.tag_percentages
    shared_tags = self.tag_percentages.map do |key, value|
      [ value, (other_tags[key] || 0) ].min
    end
    [ 100, shared_tags.inject{ |sum, n| sum + n} ].min
  end
  
  def calculate_tag_percentages
    tag_minutes = visits.includes(:tags).where("total_time > 0").map{ |v| v.tags.map { |tag| [ v.total_time, tag.name ] }}
    tm = []
    tag_minutes.flatten.each_slice(2) { |slice| tm << slice}
    total = tm.inject(0){ |sum,t| sum + t[0]}.to_f
    @tag_percentages = Hash[tm.group_by{ |tm| tm[1]}.map{ |tag| [ tag[0], tag[1].inject(0){ |sum, n| sum + n[0] } / total ]}]
  end
  
end
