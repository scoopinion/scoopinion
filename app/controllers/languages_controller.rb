class LanguagesController < ApplicationController
  
  def show
    
    @languages = [ params[:id] ]
    
    @articles = Article

    # Add filter parameter cases here
    case params[:filter_by]
      when 'friends'
        @articles = Article.joins(:visits).where(:visits => {:user_id => current_user.friends})
    end

    # Add sort by cases here
    @sort_orders = {'score' => 'Score', 'comments_count' => 'Comments', 'created_at' => 'Newest'}
    
    # General options
    limit = 20

    if params[:layout] == "false"

      if @sort_orders.include?(params[:sort_by])
        @articles = Article.joins(:site).order("#{params[:sort_by]} desc").where("articles.language IN (?)", @languages).limit(limit)
      else
        @articles = Article.feed({:user => current_user, :period => 3.days, :limit => limit, :languages => @languages})
        
        if @articles.count == 0
          @articles = Article.feed({:user => current_user, :period => 30.days, :limit => limit, :languages => @languages})
        end
        
      end

      render :partial => "articles/news"
    end
    
  end

end
