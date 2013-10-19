class Authentication < ActiveRecord::Base
  belongs_to :user
  
  has_many :twitter_shares

  validates :uid, :provider, presence: true
  validates_uniqueness_of :uid, scope: :provider

  after_save :destroy_potential, if: :facebook?

  def self.find_by_auth_hash(hash)
    Authentication.find_by_provider_and_uid(hash.provider, hash.uid)
  end

  def expired?
    case provider
    when "facebook"
      (expires_at || DateTime.new).past?
    when "twitter"
      false
    else raise "Invalid provider"
    end
  end
  
  def send_bookmark!(bookmark)
    case provider
    when "facebook"
      user = FbGraph::User.fetch(self.uid, access_token: ENV["FACEBOOK_APP_ACCESS_TOKEN"])
      return user.og_action!("scoopinion:bookmark", article: "https://www.scoopinion.com/7" + bookmark.article.short_id)
    else false
    end
  end
  
  private 

  def facebook?
    provider == "facebook"
  end

  def destroy_potential
    PotentialUser.find_by_uid(uid).try(:destroy)
  end
end
