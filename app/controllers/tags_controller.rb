class TagsController < ApplicationController
  
  respond_to :rss
  
  def index
    redirect_to root_url and return
    @tags = Tag.all
  end
  
  def show
    @tag = Tag.find_or_initialize_by_parameter(params[:id])
    if @tag.supertag
      redirect_to @tag.supertag and return
    end
    @articles = @tag.articles.where{ article_tags.created_at > 2.days.ago }.order("hotness desc").limit(10)
  end
  
end
