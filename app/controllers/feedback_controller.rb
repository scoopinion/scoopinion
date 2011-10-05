class FeedbackController < ApplicationController
  def index
  end

  def create
    Feedback.email_feedback(params[:message])
    flash[:notice] = "Thank you!" # notify successful send
    redirect_to :action => 'thankyou'
  end

  def thankyou
  end
end