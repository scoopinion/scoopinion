require 'open-uri'

class Autotagger < ActiveRecord::Base
  
  validates :condition, { 
    :presence => true
  }
  
  validates :tag, { 
    :presence => true
  }
  
  def self.test(condition)
    condition.split("|").inject(Article){ |r, keyword| r.where("LOWER(articles.url) like '%#{keyword}%'") }.each{ |a| p a.title }
  end
  
  after_create do
    delay.refresh
  end
  
  after_destroy do
    build_query(ArticleTag.includes(:article, :tag)).where("tags.name = ?", tag).each(&:destroy)
    tag_record = Tag.find_by_name(tag)
    tag_record.destroy unless tag_record.articles.exists?
  end

  def after_create(article)
    article.tag_with(tag) if keywords.all?{ |part| article.url.downcase.include?(part) || article.title.try(:downcase).try(:include?, part)}
  end
  
  def build_query(relation)
    relation = relation.includes(:alternate_urls)
    urls = keywords.inject(relation){ |r, keyword| r.where("(LOWER(articles.url) like '%#{keyword}%' OR LOWER(alternate_urls.url) like '%#{keyword}%')") }
    titles = keywords.inject(relation){ |r, keyword| r.where("LOWER(articles.url) like '%#{keyword}%'") }
    urls + titles
  end
  
  def keywords
    condition.split("|")
  end
  
  def refresh
    build_query(Article).each{ |a| a.tag_with(tag)}
  end
  
end
