class FeedsController < ApplicationController
  
  layout nil
  
  def show
    @languages = languages
  end
  
  private
  
  def languages
    return [ params[:language] ] if params[:language]
    return current_user_languages
  end
  
end
