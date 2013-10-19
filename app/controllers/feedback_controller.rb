class FeedbackController < ApplicationController
  
  helper_method :captcha_keywords
  
  def index
  end

  def create
    verify_and_respond do
      FeedbackMessage.create(:user => current_user(:anonymous => true), :message => params[:message], :email => params[:email])
    end  
  end

  def thankyou
  end

  private
  
  def captcha_keywords
    "http www .com"
  end
  
  def captcha_keyword_match?
    params[:message] && captcha_keywords.split(" ").any?{ |x| params[:message][x] }
  end
  
  def verify_and_respond
    if request.xhr?
      yield
      head :ok
    else
      if ! current_user && (captcha_keyword_match? && ! verify_recaptcha)
        flash[:notice] = t("feedback.index.captcha_error")
        render :action => :index and return
      end

      yield

      flash[:notice] = "Thank you!"
      redirect_to :action => 'thankyou'
    end
  end

end
