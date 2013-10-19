# Load the rails application
require File.expand_path('../application', __FILE__)

# Use double quotes in HAML
Haml::Template.options[:attr_wrapper] = '"'

# Initialize the rails application
Scoopinion::Application.initialize!
