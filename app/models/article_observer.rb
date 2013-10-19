class ArticleObserver < ActiveRecord::Observer
  
  observe :article
  
  def after_create(record)
    self.delay.autotag(record)
  end
  
  def autotag(article)
    Autotagger.all.each do |a|
      a.after_create(article)
    end
  end
  
end
