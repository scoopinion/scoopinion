class TagConcealmentsController < ApplicationController
  
  before_filter :require_user
  
  def create
    @concealment = current_user.tag_concealments.create(params[:tag_concealment])
    @tag = @concealment.tag
    render :partial => "tags/unblock", :locals => { :tag => @tag}
  end
  
  def destroy
    @concealment = current_user.tag_concealments.find(params[:id]).destroy
    @tag = @concealment.tag 
    render :partial => "tags/block", :locals => { :tag => @tag}
  end
  
end
