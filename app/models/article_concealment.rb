class ArticleConcealment < ActiveRecord::Base
  belongs_to :article, :inverse_of => :concealments
  belongs_to :user, :inverse_of => :concealments
  
  validates :user_id, :presence => true, :uniqueness => { :scope => :article_id }
  validates :article_id, :presence => true

end
