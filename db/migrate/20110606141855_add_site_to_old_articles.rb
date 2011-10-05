class AddSiteToOldArticles < ActiveRecord::Migration
  def change
    Article.reset_column_information
    
    Article.all.each do |article|
      site = Site.find_by_full_url(article.url)
      article.site = site
      article.save
      if article.site_id
        puts "Site for #{article.title} is #{site.title}"
      else
        puts "Error finding site for #{article}"
      end
    end
    
  end
end
