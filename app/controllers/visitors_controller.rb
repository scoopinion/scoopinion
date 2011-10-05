class VisitorsController < ApplicationController
  
  layout "iframe", :if => Proc.new{ params[:iframe] }
  before_filter :strip_dot
  
  def index
    unless @article = Article.find_by_id(params[:article_id])
      @article = Article.find_by_url(params[:article_id])
    end
    
    unless @article
      @article = Article.new
    end

    
    @visitors = (@article.visitors.select{|u| current_user.friend_of?(u) } + [ current_user ]).uniq
    if params[:iframe]
      render "articles/iframe"
    else
      render :partial => "articles/visitors"
    end
  end
  
  private
  
  def single_access_allowed?
    true
  end
  
  def strip_dot
    params[:article_id].gsub!("$dot", ".").gsub!(/\/$/, "")
  end
  
end


