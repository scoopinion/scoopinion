Huomenet::Application.routes.draw do

  root :to => "Articles#index"

  resources :visits, :user_sessions, :users, :sites, 
  :comments, :notifications, :languages, :recommendations, 
  :tags, :tag_concealments, :tag_predictions, :article_tags
  
  resource :feed
  
  
  resources :authentications
  match '/auth/:provider/callback' => 'authentications#create'

  resources :articles do
    resources :concealments
    resources :visitors
  end

  resources :feedback, :only => [:index, :create]
  get 'feedback/thankyou'
  
  match 'teach' => "tag_predictions#index"
  match 'search' => "search#index"
  match 'search/:query' => "search#show"
  
  match "crx/(:api_key)" => "Extensions#show", :as => :extension
  match "crx/:api_key/update" => "Extensions#update", :as => :update_extension, :format => :xml

  match "logout" => "UserSessions#destroy"
  match "whitelist" => "Sites#index"

  match "stats" => "Stats#index"

  match "friendships" => "friendships#index"
  post "friendships/create"
  
  match "favicon.ico" => "Application", :action => :favicon
  match ":page" => "Pages#show", :as => :page
  
end
