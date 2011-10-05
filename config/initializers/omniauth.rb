Rails.application.config.middleware.use OmniAuth::Builder do
  # List of authentication providers
  provider :facebook, Rails.application.config.facebook_app_id, Rails.application.config.facebook_secret, {:scope => 'email', :client_options => {:ssl => {:ca_path => "/etc/ssl/certs"}}}
end
