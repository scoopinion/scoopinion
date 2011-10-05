class TagsController < ApplicationController
  
  def index
    @tags = Tag.all
  end
  
  def show
    @tag = Tag.find_or_initialize_by_parameter(params[:id])
    if @tag.supertag
      redirect_to @tag.supertag and return
    end
    @articles = @tag.articles.in_languages(current_user_languages).sort_by(&:hotness).reverse.take(50)
  end
  
end
