class SitesController < ApplicationController

  before_filter :require_user, :only => :create
  before_filter :require_admin, :only => [ :update, :destroy ]

  respond_to :json, :html

  def index
    @sites = Site.confirmed
    @all_sites = Site.order("name asc")
    @site = Site.new
    respond_to do |format|
      format.html
      format.json { response.headers['Cache-Control'] = 'public, max-age=300' }
    end
  end

  def show
    @site = Site.find(params[:id])
  end

  def create
    @site = current_user.suggested_sites.create(params[:site])
    if @site.valid?
      redirect_to sites_url, :notice => "Thanks! We will review your suggestion as soon as we can."
    else
      @sites = Site.confirmed
      @all_sites = Site.order("name asc")
      @site = Site.new
      render :action => :index
    end
  end

  def update
    @site = Site.find(params[:id])
    @site.update_attributes(params[:site])
    redirect_to sites_url
  end
  
  def destroy
    @site = Site.find(params[:id])
    @site.destroy
    redirect_to sites_url
  end
  
end
