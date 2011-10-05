class SearchController < ApplicationController
  
  before_filter :require_admin
  
  def index
    @articles = Article.search(params[:query])
  end
  
  def show
    @articles = Article.search(params[:query])
  end
  
end
