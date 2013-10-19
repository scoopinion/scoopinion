class ExtensionsController < ApplicationController
  
  def index
    { :api_key => params[:user_credentials] || "scoopinion" }.tap do |redirect_params|
      if chrome?
        redirect_to extension_url(redirect_params)
      elsif firefox?
        redirect_to firefox_extension_url(redirect_params)
      else
        redirect_to page_url("extension")
      end
    end
  end
  
end


