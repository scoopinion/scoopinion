class Comment < ActiveRecord::Base

  belongs_to :article, :inverse_of => :comments, :counter_cache => true, :touch => true
  belongs_to :user, :inverse_of => :comments

  has_many :notifications, :as => :reason, :dependent => :destroy

  validates_presence_of :article_id
  validates_presence_of :user_id
  validates_presence_of :body

  after_create do
    commenters = self.article.comments.map(&:user)
    visitors = self.article.visitors

    (commenters + visitors).uniq.each do |u|
      self.notifications.create(:user => u, :subject => self.user)
    end
  end

  def as_json(options={})
    super(options.merge(:include => [:user]))
  end

end
