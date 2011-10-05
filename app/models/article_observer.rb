class ArticleObserver < ActiveRecord::Observer
  
  observe :article
  
  def after_create(record)
    Autotagger.all.each do |a|
      a.after_create(record)
    end
  end
  
end
