# == Schema Information
# Schema version: 20110603153902
#
# Table name: sites
#
#  id         :integer         not null, primary key
#  url        :string(255)
#  title      :string(255)
#  created_at :datetime
#  updated_at :datetime
#

require 'transitions'

class Site < ActiveRecord::Base

  include ActiveRecord::Transitions

  validates :title, {
      :presence => true,
      :length => {:minimum => 1}
  }

  validates :url, {
      :presence => true,
      :uniqueness => true,
      :length => {:minimum => 1},
      :format => {:with => /^[a-z]+[a-z0-9\-.]*\.[a-z0-9\-\/.]*[a-z0-9]+$/}
  }

  has_many :articles

  before_create do
    state = "suggested"
  end
  
  after_create do
    self.delay.guess_language
  end

  state_machine do
    state :suggested
    state :confirmed
    state :rejected
  end

  scope :confirmed, where("state = 'confirmed' OR state IS NULL")
  scope :suggested, where("state = 'suggested'")
  scope :rejected, where("state = 'rejected'")

  def self.find_by_full_url(url)
    cleansed_url = url.gsub(/#.*$/, "")
    cleansed_url.gsub!(/\?.*$/, "")
    cleansed_url.gsub!(/^.*?:\/\//, "")
    cleansed_url.gsub!(/\/.*/, "")

    server = cleansed_url
    server_parts = server.split(".")

    site_url = server_parts.pop

    server_parts.reverse.each do |part|
      site_url = "#{part}.#{site_url}"
      site = Site.confirmed.where("url = ?", site_url).first
      return site if site
    end

    return nil
  end

  def as_json(options={})
    {
      :url => url,
      :title => title,
      :language => language
    }
  end

  def initial
    return '?' if title.blank?
    title.slice(0).chr.upcase
  end
  
  def guess_language
    @@d ||= LanguageDetector.new
    body = self.stripped_body
    if body.length > 10
      self.language = @@d.detect(body)
      self.save
    end
    return self.language
  end
  
  def stripped_body
    require 'open-uri'
    open("http://" + url).read.gsub("\n", " ").gsub("\t","").gsub("\r", "").gsub(/<script.*?>.*?<\/script>/, "").gsub(/<style.*?>.*?<\/style>/, "").gsub(/<\/?[^>]*>/, "") rescue ""
  end
  
end

