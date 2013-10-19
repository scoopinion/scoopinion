class FeedsController < ApplicationController

  respond_to :json
  
  before_filter :require_user, :only => :index
  
  def index
    if (params[:issue] == "true" || !request.xhr?) and @issue = find_issue
      @featured = @issue
    else
      params[:timeframe] = "daily"
      @featured = Feeds::Featured.new(additional_params)
    end
        
    @main_feed = Feeds::Main.new(additional_params) if request.xhr?
  end

  def show  
    case params[:type]
    when "main"
      if params[:issue] && @issue = find_issue
        @feed = @issue
      else
        @feed = Feeds::Main.new(additional_params)
      end
    when "featured"
      if params[:issue] && @issue = find_issue
        @feed = @issue
      else
        @feed = Feeds::Featured.new(additional_params)
      end
    when "just_in" 
      @feed = Feeds::JustIn.new(additional_params)
    when "favorite_authors"
      @feed = Feeds::FavoriteAuthors.new(additional_params)
    else 
      @feed = Feeds::Main.new(additional_params)
    end
    
    respond_to do |format|
      format.json
      format.rss
    end
  end
  
  private

  def single_access_allowed?
    true
  end
  
  def languages
    return [ params[:language] ] if params[:language]
    return current_user_languages
  end

  def additional_params
    params.merge({ user: current_user, languages: languages })
  end

  def find_issue
    return nil unless current_user
    issue = current_user.current_issue
    return issue
  end

end
