class TagPredictionsController < ApplicationController
  
  before_filter :require_admin
  
  def index
    if params[:tag] && @tag = Tag.find_by_name(params[:tag])
      @predictions = TagPrediction.where(:state => [ "new", "assumed"], :tag_id => @tag.id).where("confidence > 0.2").order("ABS(confidence - 0.5)").limit(10)
    else  
      @predictions = TagPrediction.where(:state => [ "new", "assumed" ]).includes(:article).order("ABS(confidence - 0.5)").limit(20)
    end
    
    if request.xhr?
      render :partial => "prediction_list" and return
    end
  end
  
  def update
    if @prediction = TagPrediction.find_by_id(params[:id])
      @prediction.update_attributes(params[:tag_prediction])
    end
    render :json => { :status => :ok }
  end
  
end
