Scoopinion::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = true
  
  config.assets.compress = true
  config.assets.compile = false
  config.assets.digest = true
  
  config.static_cache_control = "public, max-age=30758400" 
  
  # Compress both stylesheets and JavaScripts
  config.assets.js_compressor  = :uglifier
  config.assets.css_compressor = :scss
  
  config.static_cache_control = "public, max-age=30758400" 
  
  # Specifies the header that your server uses for sending files
  # (comment out if your front-end server doesn't support this)
  config.action_dispatch.x_sendfile_header = nil

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  config.cache_store = :dalli_store

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  config.assets.precompile += %w( analytics.js iframe.js iframe.css stats.js distraction_free.css distraction_free.js modernizr.js extension.js landing.css landing.js jquery.js landing_specific.css profile.css profile.js scoopinion.css)
  
 # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  config.email_link_host = "scoopinion-staging-cedar.heroku.com"
end
