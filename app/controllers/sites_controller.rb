class SitesController < ApplicationController

  before_filter :require_user, :only => :create
  before_filter :require_admin, :only => :update

  respond_to :json, :html

  def index
    @sites = Site.order("title ASC")
    @site = Site.new

    respond_with(@sites) do |format|
      format.html
      format.json do
        render :json => @sites.confirmed
      end
    end
  end

  def show
    @site = Site.find(params[:id])
    @articles = @site.articles.sort_by(&:hotness).reverse.take(50)
  end

  def create
    params[:site][:url].gsub!("http://", "")
    @site = Site.create(params[:site])
    if @site.valid?
      redirect_to sites_url, :notice => "Thanks! We will review your suggestion as soon as we can."
    else
      @sites = Site.order("articles_count DESC")
      render :action => :index
    end
  end

  def update
    @site = Site.find(params[:id])
    @site.update_attributes(params[:site])
    redirect_to @site
  end

end
