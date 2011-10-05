class ArticlesController < ApplicationController
  
  before_filter :require_user, :only => :destroy
  
  respond_to :json, :html

  def index
    
    @languages = current_user_languages
    
    if current_user && !params[:layout]
      Recommender.generate(current_user)
    end
    
    @articles = Article

    # Add filter parameter cases here
    case params[:filter_by]
      when 'friends'
        @articles = @articles.joins(:visits).where(:visits => {:user_id => current_user.friends})
    end

    # Add sort by cases here
    @sort_orders = {'score' => 'Score', 'comments_count' => 'Comments', 'created_at' => 'Newest', 'average_time' => 'Longest'}

    options = { 
      :user => current_user, 
      :period => 3.days, 
      :limit => 20, 
      :languages => @languages, 
      :min_time => params[:min_time]
    }
    
    @weekend = weekend? && params[:weekend] != "off"
        
    if params[:layout] == "false"
      if @sort_orders.include?(params[:sort_by])
        options[:order] = "articles.#{params[:sort_by]}"
        options[:period] = 7.days
      elsif @weekend
        options[:sort] = :interestingness
        options[:order] = nil
        options[:min_time] = 120
        options[:period] = 7.days
        options[:min_visitors] = 2
        options[:unread_only] = true
      else 
        options[:sort] = :hotness
      end
      @articles = @articles.feed(options)
      render :partial => "news"
    end
  end

  def show
    @article = Article.find_by_id(params[:id])
    respond_with(@article) do |format|
      format.json do
        render :json => @article.as_json(:include => {
            :comments => {
                :only => [:id, :body],
                :include => {
                    :user => {
                        :only => [:id],
                        :methods => [:display_name]
                    }
                }
            },
            :visits => {
                :only => :user,
                :include =>{
                    :user => {
                        :only => [:id],
                        :methods => [:display_name]
                    }
                }
            }
        })
      end
      format.html do
        if request.xhr?
          render :partial => "sidebar", :locals => {:article => @article}
        end
      end
    end
  end

  private

  def single_access_allowed?
    true
  end
  
end

