# -*- coding: utf-8 -*-
module ArticleHelper
  
  require 'digest/md5'
  
  def instapaper_iframe(article)
    <<STR
    <iframe border="0" scrolling="no" width="78" height="17" allowtransparency="true" frameborder="0"
 style="margin-bottom: -3px; z-index: 1338; border: 0px; background-color: transparent; overflow: hidden;"
 src="http://www.instapaper.com/e2?url=#{URI::encode(article.full_url)}&title=#{URI::encode(article.title)}"
></iframe>
STR
  end
  
  def article_description(article)
    byline = article.site.try(:name)
    if article.authors.count <= 3 && article.authors.count > 0
      byline = article.authors.map(&:name).join(", ") + ", " + byline
    end
    (byline + " — " + @article.clean_summary.join(" ")).html_safe
  end
  
  def instapaper_url(article)
    "http://www.instapaper.com/hello2?url=#{URI::encode(article.full_url)}"
  end
  
  def article_tweet_button(article)
    link_to "Tweet", "https://twitter.com/share", { :class => "twitter-share-button" }.merge(article_tweet_options(article))
  end
  
  def article_tweet_options(article)
    { 
      "data-url" => short_article_url(article, :host => "scpn.in", :protocol => "http", :port => nil),
      "data-text" => article_tweet_text(article),
      "data-count" => "none"
    }
  end
  
  def article_tweet_text(article)
    by = ""
    if article.author.try(:twitter)
      by = " by @#{article.author.twitter}"    
    else
      by = " (#{article.site.name})"
    end
    "#{article.title}#{by}"
  end
  
  def article_class(article, index = nil, activate_first = false)
    classes = ["article"]
    if params[:controller] != "users" && params[:no_grays] != "true" && current_user && current_user.visited?(article)
      classes << "previously-visited"
    end
    
    if activate_first
      classes << "view" if index == 0
    end
    
    classes.join(" ")
  end
  
  def cache_key(articles)
    return Time.now if current_user
    Digest::MD5.hexdigest(articles.map{ |a| "#{a.id}#{a.updated_at.to_i}" }.join)
  end
  
  def heatmap_background(heatmap)
    
    return "" unless heatmap
    
    background = "-webkit-gradient(linear, left top, left bottom"
    
    heatmap.each_with_index do |i, index|
      hue = [ 0, 230 - (i*2) ].max.round
      lightness = [ 50, 100 - i * 2].max.round
      background = background + ", color-stop(#{index / heatmap.size.to_f}, hsl(#{hue}, 100%, #{lightness}%))"
    end

    background = background + ")"
    
  end

  def byline(a)
    if a.author
    "#{a.author.name}, #{a.site.name}"
    elsif a.site
      a.site.name
    else
      ""
    end
  end
  
  def local_article_url(article, options = { })
    options[:source] ||= "scoopinion"
    short_article_path(article, :original_url => article.full_url, :source => options[:source])
  end
  
end
