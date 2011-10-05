class ConcealmentsController < ApplicationController
  
  before_filter :require_user, :only => :create

  def create
    @article = Article.find(params[:article_id])
    @article.concealments.create(:user => current_user)
    render :json => { :status => :ok }
  end
  
end
