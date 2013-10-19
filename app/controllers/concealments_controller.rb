class ConcealmentsController < ApplicationController
  
  before_filter :require_user

  def index
    @concealments = current_user.concealments.group_by(&:concealable_type).sort
  end

  def create
    @concealment = current_user.concealments.create(params[:concealment])
    current_user.current_issue.try :remove_concealed!
    head :ok
  end
  
  def destroy
    @concealment = current_user.concealments.find(params[:id]).destroy
    flash[:notice] = "Deleted"
    redirect_to(:back)
  end
  
end
