Rails.application.config.middleware.use OmniAuth::Builder do
  # List of authentication providers
  provider :facebook, ENV["FACEBOOK_APPID"], ENV["FACEBOOK_SECRET"], {:scope => 'email,user_birthday', :client_options => {:ssl => {:ca_path => "/etc/ssl/certs"}}}
  provider :twitter, ENV["TWITTER_KEY"], ENV["TWITTER_SECRET"]
end
