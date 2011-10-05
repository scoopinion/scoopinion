class ExtensionsController < ApplicationController
  
  def show
    @key = params[:api_key]
    
    unless current_user = User.find_by_single_access_token(@key)
      render :status => :unauthorized and return
    end
    
    name = "Scoopinion"
    name = "Scoopinion Localhost" if request.local?
    
    @extension_file = Extension.build(:key => params[:api_key], 
                                      :name => name,
                                      :server_url => root_url.chop,
                                      :update_url => update_extension_url(params[:api_key]),
                                      :user_id => current_user.id)
    
    if @extension_file
      send_file "#{@extension_file}", :type => "application/x-chrome-extension" and return
    end          
  end
  
  def update
    @extension_url = extension_url(params[:api_key])
    
    manifest = File.open("#{Rails.root}/extension/src/manifest.json", 'rb') { |f| f.read }
    
    @version = JSON.parse(manifest)["version"]
    @app_id = Rails.application.config.chrome_extension_id
  end
  
end
