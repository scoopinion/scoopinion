# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110909075741) do

  create_table "article_concealments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "article_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "article_tags", :force => true do |t|
    t.integer  "article_id"
    t.integer  "tag_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "article_tags", ["article_id"], :name => "index_article_tags_on_article_id"

  create_table "articles", :force => true do |t|
    t.string   "url"
    t.string   "title"
    t.integer  "visits_count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "score",                 :default => 0
    t.integer  "site_id"
    t.integer  "comments_count",        :default => 0
    t.text     "description"
    t.string   "image_url"
    t.string   "language"
    t.integer  "finder_id"
    t.integer  "average_time"
    t.datetime "average_visiting_time"
    t.boolean  "in_neutral_corpus"
  end

  add_index "articles", ["title", "site_id"], :name => "index_articles_on_title_and_site_id"
  add_index "articles", ["url"], :name => "index_articles_on_url"

  create_table "authentications", :force => true do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "uid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "autotaggers", :force => true do |t|
    t.string   "condition"
    t.string   "tag"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "badges", :force => true do |t|
    t.integer  "user_id"
    t.string   "badge_type"
    t.integer  "level"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", :force => true do |t|
    t.integer  "article_id"
    t.integer  "user_id"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["article_id"], :name => "index_comments_on_article_id"
  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.text     "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "friendships", :force => true do |t|
    t.integer  "user_id"
    t.integer  "friend_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "compatibility"
    t.datetime "compatibility_updated_at"
    t.boolean  "recalculation_scheduled"
  end

  create_table "notifications", :force => true do |t|
    t.integer  "user_id"
    t.integer  "reason_id"
    t.string   "reason_type"
    t.string   "state",       :default => "new"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "subject_id"
  end

  create_table "recommendations", :force => true do |t|
    t.integer  "user_id"
    t.integer  "article_id"
    t.string   "state"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sites", :force => true do |t|
    t.string   "url"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "articles_count",         :default => 0
    t.string   "state"
    t.boolean  "truncate_leading_title"
    t.string   "language"
  end

  add_index "sites", ["url"], :name => "index_sites_on_url"

  create_table "tag_concealments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "tag_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tag_predictions", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "article_id"
    t.float    "confidence"
    t.string   "state"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "reevaluation_scheduled"
  end

  create_table "tags", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "parameter"
    t.integer  "supertag_id"
    t.datetime "recalculated_at",             :default => '2011-08-17 10:21:34'
    t.integer  "new_data_since_recalculated", :default => 0
  end

  create_table "token_frequencies", :force => true do |t|
    t.integer  "token_id"
    t.integer  "tag_id"
    t.integer  "count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "token_frequencies", ["token_id"], :name => "index_token_frequencies_on_token_id"

  create_table "tokens", :force => true do |t|
    t.string   "name"
    t.integer  "count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "genericity"
  end

  add_index "tokens", ["name"], :name => "index_tokens_on_name"

  create_table "user_languages", :force => true do |t|
    t.integer  "user_id"
    t.string   "language"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "login",                  :null => false
    t.string   "email",                  :null => false
    t.string   "crypted_password",       :null => false
    t.string   "password_salt",          :null => false
    t.string   "persistence_token",      :null => false
    t.string   "single_access_token",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "friends_updated_at"
    t.datetime "extension_installed_at"
  end

  create_table "visits", :force => true do |t|
    t.integer  "user_id"
    t.integer  "article_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "score"
    t.text     "referrer"
    t.integer  "total_time"
    t.integer  "total_scrolled"
    t.integer  "link_click"
    t.integer  "right_click"
    t.integer  "mouse_move"
    t.integer  "link_hover"
    t.integer  "arrow_up"
    t.integer  "arrow_down"
    t.integer  "scroll_down"
    t.integer  "scroll_up"
  end

  add_index "visits", ["article_id", "user_id"], :name => "index_visits_on_article_id_and_user_id"

end
