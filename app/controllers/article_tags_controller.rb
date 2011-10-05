class ArticleTagsController < ApplicationController
  
  before_filter :require_admin
  
  def create
    @name = params[:tag].strip.downcase
    
    unless Tag.find_by_name(@name) || params[:create_new_tag]
      render :json => { :status => :confirmation_needed, :new_tag => @name } and return
    end
    
    @article = Article.find(params[:article_id])
    @article.tag_with(params[:tag])
    render :json => { :status => :ok }
  end
  
  def destroy
    @article_tag = ArticleTag.find params[:id]
    @article_tag.destroy
    render :json => { :status => :ok }
  end
  
end
