module ArticleHelper
  
  require 'digest/md5'
  
  def feed_title
    return "Scoops for the weekend" if @weekend
    case params[:sort_by]
    when "comments_count"
      return "Most commented scoops of the week"
    when "score"
      return "Highest-scoring scoops of the week"
    when "created_at"
      return "Newest scoops"
    end
    "Scoops of the day"
  end

  
  def article_class(article, index = nil, activate_first = false)
    classes = ["article"]
    if params[:controller] != "users" && article.visitors.include?(current_user)
      classes << "visited"
    end
    
    if activate_first
      classes << "view" if index == 0
    end
    
    classes.join(" ")
  end

  def comment_button_class(article)
    classes = ["comment"]
    classes << "nonzero" if article.comments_count > 0
    classes.join(" ")
  end

  def comments_link_text(article)
    return "Comment" if article.comments_count == 0 || article.comments_count == nil

    noun = "comment"
    noun = noun.pluralize if article.comments_count > 1
    return "#{article.comments_count} #{noun}"
  end
  
  def md5(array)
    Digest::MD5.hexdigest(array.flatten.join)
  end
  
  def cache_key(articles)
    return Time.now if current_user
    Digest::MD5.hexdigest(articles.map{ |a| "#{a.id}#{a.updated_at.to_i}" }.join)
  end
  
end
