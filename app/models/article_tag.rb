class ArticleTag < ActiveRecord::Base
  belongs_to :article, :inverse_of => :article_tags, :touch => true
  belongs_to :tag, :inverse_of => :article_tags, :touch => true
  
  validates :article_id, { 
    :presence => true,
    :uniqueness => { 
      :scope => :tag_id
    }
  }
  
  validates :tag_id, { 
    :presence => true
  }
  
  before_create do
    if tag.try(:supertag_id)
      self.tag_id = tag.supertag_id
    end
  end
  
  def self.for(article, tag)
    where(:article_id => article.id, :tag_id => tag.id).first
  end
  
end
