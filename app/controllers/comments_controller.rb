class CommentsController < ApplicationController
  
  before_filter :require_user
  
  def create
    @comment = current_user.comments.create(params[:comment])
    redirect_to @comment.article
  end
  
  private
  
  def single_access_allowed?
    true
  end
  
end


