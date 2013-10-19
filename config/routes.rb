require "logged_in_constraint"
require "logged_out_constraint"
require "params_constraint"
require "and_constraint"

Scoopinion::Application.routes.draw do
  
  get "invitations/create"
  
  root :to => "landing#index", constraints: LoggedOutConstraint.new
  root :to => "feeds#index"
  
  match "invite" => "landing#index"
  match "/weekly" => "Feeds#index", :anchor => "top"
  match "/hot" => "Feeds#index"

  match "/feeds/:type" => "Feeds#show", :format => :json
  resources :feeds, :format => :json
  
  match 'status' => "Status#index"

  match "journalists" => "author_insights#index", as: :author_insights
  
  match "authors/fi" => "Authors#index"
  
  match "bingo/:conversion" => "Bingo#create"
  
  resources :author_lists
  resources :analytics
  resources :api_sessions
  resources :article_tags
  resources :articles do
    resources :visitors
  end
  resources :concealments
  resources :authentications
  resources :authors do
    resources :analytics
  end
  resources :details
  resources :email_analytics
  resource :feed
  resources :feedback, :only => [:index, :create]
  resources :boolean_feedback, :only => :create

  match 'friendships/:uid' => "friendships#update", :as => :update_friendship, :via => :post

  resource :feed
  resources :history_items
  resources :sites do
    resources :analytics
  end
  resources :tag_concealments
  resources :tags
  resources :tests
  resources :unsubscriptions
  resources :user_sessions
  resources :users
  resources :data_requests, only: [:show, :new, :create]
  resources :visits

  resources :twitter_shares, only: [:create, :show]
  resources :facebook_shares, only: [:create, :show]
  resources :email_shares, only: [:create, :show]
  
  resources :digest_time_slots

  resources :digest_subscribes, only: [:create]
  resources :author_subscribes, only: [:create]
  
  resources :blog do
    resources :revisions, :controller => "BlogPostRevisions"
  end
  
  match "labs/24/(:language)" => "TopLists#show", :as => "top_list"
  match "labs/neighborhood" => "Neighborhoods#show", :as => "neighborhood"
  match "labs/best-of-2012/(:language)" => "TopLists#show", :as => "best_of_2012", :key => "best-of-2012"
  
  resources :issues
  resources :password_requests
  resources :password_resets
  resources :invitations
  resources :scraping_rules
  resources :content_experiments
  resources :labs
  resources :testimonials, only: :index
  resources :bookmarks, only: [:index, :create, :destroy], path: "reading_list"
  
  resource :redirect
  
  get "unsubscriptions/show"
  get "firefox_extensions/show"
  get "firefox_extensions/update"
  
  get 'feedback/thankyou'
  
  get 'profiles/:id/(:key)' => "Profiles#show", :as => :shareable_profile
  resources :profiles
  
  match "settings" => "settings#update", as: "update_settings", via: :post
  
  match "user_settings" => "user_settings#update", as: "update_user_settings", via: :put
  match "user_settings" => "user_settings#index", as: "user_settings" 
  match "settings" => "user_settings#index", as: "settings"
  
  
  match "favicon.ico" => "Application", :action => :favicon
  
  match "logout" => "UserSessions#destroy"
  
  match "stats" => "Stats#index"
  match "stats/users" => "UserStats#index"
  
  match "whitelist/votes" => "WhitelistVotes#create", via: :post
  
  match "whitelist/(:list_type)" => "Sites#index", as: "whitelist"
  
  match "xpi/(:api_key).xpi" => "FirefoxExtensions#show", :as => :firefox_extension
  match "xpi/:api_key/update" => "FirefoxExtensions#update", :as => :update_firefox_extension
  
  match "/auth/:provider/callback" => "authentications#create"
  match "auth/failure" => "authentications#failure"

  
  match 'articles/:id.:format' => "Articles#show", :constraints => { :id => /.*/ }  
  
  match 'friendships/:uid' => "friendships#update", :as => :update_friendship, :via => :post
  
  match 'search' => "search#index"
  match 'search/:query' => "search#show"
  
  namespace :debug do
    match 'login/:id' => "Login#show"
  end
  
  match '7:short_id' => "articles#show", :as => :short_article
    
  match "extension_redirect", :to => "Extensions#index", :as => :extension_redirect
    
  namespace :admin do
    resource :graylist
    resource :blacklist
    resource :whitelist
  end
  
  match 'admin/abingo(/:action(/:id))', :to => 'abingo_dashboard', :as => :bingo
  
  match 'admin/:class', :to => 'admin_spreadsheets#show', :as => :spreadsheets, :via => :get
  match 'admin/:class', :to => 'admin_spreadsheets#create', :as => :spreadsheets, :via => :post
  match 'admin/:class/:id', :to => 'admin_spreadsheets#update', :via => :put, :as => :spreadsheet
  
  match "stats/retention", :to => "Pages#show", :page => "cohort_stats"
  
  match "dublin-web-summit-2012", :to => "AuthorLists#show", :id => 1
  
  match "introduction/(:step)" => "Introduction#show", as: "introduction"
  match "addon" => "Introduction#show", step: "addon", standalone: true, as: "standalone_addon"
  match "extension" => "Introduction#show", step: "addon", standalone: true
  
  if Rails.env.development?
    mount NewDigestMailer::Preview => 'mail_view'
    mount UserMailer::Preview => 'user_mail_view'
  end
    
  match ":page/(:subpage)" => "Pages#show", :as => :page
  
  
end
