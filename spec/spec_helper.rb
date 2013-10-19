# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'authlogic/test_case'

include Authlogic::TestCase

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true
end

OmniAuth.config.test_mode = true
user_hash = {
  uid: "123456789"
}
OmniAuth.config.add_mock(:facebook, user_hash.merge(info: { email: "user@example.com" }, credentials: { token: "facebook token", expires_at: 1321747205 }))
OmniAuth.config.add_mock(:twitter, user_hash.merge(credentials: { token: "twitter token", secret: "secret token"}))


def login_as(user)
  controller.stub!(:current_user).and_return(user) unless user.anonymous?
  controller.stub!(:current_or_anonymous_user).and_return(user)
end

def logout
  controller.stub!(:current_user).and_return(nil)
  controller.stub!(:current_or_anonymous_user).and_return(nil)
end

def stub_omniauth
  omniauth = {"provider"=>"facebook", "uid"=>"1234567", "info"=>{"nickname"=>"jbloggs", "email"=>"user@example.com", "name"=>"Joe Bloggs", "first_name"=>"Joe", "last_name"=>"Bloggs", "image"=>"http://graph.facebook.com/1234567/picture?type=square", "urls"=>{:Facebook=>"http://www.facebook.com/jbloggs"}, "location"=>"Palo Alto, California"}, "credentials"=>{"token"=>"ABCDEF...", "expires_at"=>1321747205, "expires"=>true}, "extra"=>{"raw_info"=>{"id"=>"1234567", "name"=>"Joe Bloggs", "first_name"=>"Joe", "last_name"=>"Bloggs", "link"=>"http://www.facebook.com/jbloggs", "username"=>"jbloggs", "location"=>{:id=>"123456789", :name=>"Palo Alto, California"}, "gender"=>"male", "email"=>"joe@bloggs.com", "timezone"=>-8, "locale"=>"en_US", "verified"=>true, "updated_time"=>"2011-11-11T06:21:03+0000"}}}
  controller.stub!(:get_omniauth).and_return(omniauth)
end

def use_browser(browser)
  view.stub!(:chrome?).and_return false
  view.stub!(:firefox?).and_return false
  if browser
    view.stub!("#{browser}?").and_return true
  end
end

include ActionView::Helpers::SanitizeHelper 

def normalize(text)
  sanitize(text, :tags => [], :attributes => []).gsub(/\s+/, " ")
end
