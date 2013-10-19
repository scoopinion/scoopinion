class RecommendationsController < ApplicationController
  
  before_filter :require_user
  
  def index
    Recommender.generate(current_user)
    @articles = current_user.recommended_articles
  end
  
  def show
    Recommender.generate(current_user)
    render :partial => "recommendations/recommendation", :locals => { :recommendation => current_user.recommendations.first }
  end
  
end
