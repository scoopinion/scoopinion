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

ActiveRecord::Schema.define(:version => 20130225070422) do

  create_table "ab_test_notifications", :force => true do |t|
    t.integer  "experiment_id"
    t.float    "p_value"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "abingo_experiment_participations", :force => true do |t|
    t.integer  "user_id"
    t.integer  "alternative_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "abingo_experiment_participations", ["alternative_id"], :name => "index_abingo_experiment_participations_on_alternative_id"
  add_index "abingo_experiment_participations", ["user_id", "alternative_id"], :name => "index_aep_on_user_id_and_alternative_id", :unique => true

  create_table "alternate_names", :force => true do |t|
    t.integer  "site_id"
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "alternate_names", ["name"], :name => "index_alternate_names_on_name"
  add_index "alternate_names", ["site_id"], :name => "index_alternate_names_on_site_id"

  create_table "alternate_urls", :force => true do |t|
    t.integer  "article_id"
    t.text     "url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "alternate_urls", ["url"], :name => "index_alternate_urls_on_url"

  create_table "alternatives", :force => true do |t|
    t.integer "experiment_id"
    t.string  "content"
    t.string  "lookup",        :limit => 32
    t.integer "weight",                      :default => 1
    t.integer "participants",                :default => 0
    t.integer "conversions",                 :default => 0
  end

  add_index "alternatives", ["experiment_id"], :name => "index_alternatives_on_experiment_id"
  add_index "alternatives", ["lookup"], :name => "index_alternatives_on_lookup"

  create_table "article_concealments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "article_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "article_mailings", :force => true do |t|
    t.integer  "user_id"
    t.integer  "article_id"
    t.datetime "clicked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "opened_at"
    t.integer  "digest_email_id"
  end

  add_index "article_mailings", ["created_at"], :name => "index_article_mailings_on_created_at"
  add_index "article_mailings", ["digest_email_id"], :name => "index_article_mailings_on_digest_email_id"
  add_index "article_mailings", ["user_id", "created_at"], :name => "index_article_mailings_on_user_id_and_created_at_partially"
  add_index "article_mailings", ["user_id"], :name => "index_article_mailings_on_user_id"

  create_table "article_referrals", :force => true do |t|
    t.integer  "article_id"
    t.integer  "referrer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "article_referrals", ["article_id"], :name => "index_article_referrals_on_article_id"

  create_table "article_scores", :force => true do |t|
    t.integer  "article_id"
    t.string   "key"
    t.integer  "score"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "trend"
  end

  add_index "article_scores", ["article_id"], :name => "index_article_scores_on_article_id"
  add_index "article_scores", ["key", "article_id"], :name => "index_article_scores_on_key_and_article_id"
  add_index "article_scores", ["key"], :name => "index_article_scores_on_key"
  add_index "article_scores", ["score"], :name => "index_article_scores_on_score"

  create_table "article_tags", :force => true do |t|
    t.integer  "article_id"
    t.integer  "tag_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "article_tags", ["article_id"], :name => "index_article_tags_on_article_id"
  add_index "article_tags", ["tag_id"], :name => "index_article_tags_on_tag_id"

  create_table "articles", :force => true do |t|
    t.text     "url"
    t.string   "title"
    t.integer  "visits_count",                        :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "score",                               :default => 0
    t.integer  "site_id"
    t.text     "description"
    t.text     "image_url"
    t.string   "language",              :limit => 16
    t.integer  "finder_id"
    t.integer  "average_time"
    t.datetime "average_visiting_time"
    t.boolean  "in_neutral_corpus"
    t.float    "hotness",                             :default => 0.0
    t.text     "summary"
    t.text     "image"
    t.integer  "image_width"
    t.integer  "image_height"
    t.integer  "thumb_width"
    t.integer  "thumb_height"
    t.datetime "published_at"
    t.datetime "crawled_at"
    t.integer  "word_count"
    t.integer  "rating"
    t.boolean  "suitable",                            :default => false
    t.string   "content",               :limit => 16
    t.boolean  "featured"
  end

  add_index "articles", ["average_visiting_time"], :name => "index_articles_on_average_visiting_time"
  add_index "articles", ["created_at"], :name => "index_articles_on_created_at"
  add_index "articles", ["hotness", "average_visiting_time"], :name => "index_articles_for_feed_lang_"
  add_index "articles", ["hotness", "average_visiting_time"], :name => "index_articles_for_feed_lang_en"
  add_index "articles", ["hotness", "average_visiting_time"], :name => "index_articles_for_feed_lang_en_fi"
  add_index "articles", ["hotness", "average_visiting_time"], :name => "index_articles_for_feed_lang_fi"
  add_index "articles", ["hotness", "average_visiting_time"], :name => "index_articles_on_hotness_and_average_visiting_time"
  add_index "articles", ["language"], :name => "index_articles_on_language"
  add_index "articles", ["score", "average_visiting_time"], :name => "index_articles_for_digest_lang_", :order => {"score"=>:desc}
  add_index "articles", ["score", "average_visiting_time"], :name => "index_articles_for_digest_lang_en", :order => {"score"=>:desc}
  add_index "articles", ["score", "average_visiting_time"], :name => "index_articles_for_digest_lang_en_fi", :order => {"score"=>:desc}
  add_index "articles", ["score", "average_visiting_time"], :name => "index_articles_for_digest_lang_fi", :order => {"score"=>:desc}
  add_index "articles", ["score"], :name => "index_articles_on_score"
  add_index "articles", ["site_id"], :name => "index_articles_on_site_id"
  add_index "articles", ["url"], :name => "index_articles_on_url"

  create_table "authentications", :force => true do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "uid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "token"
    t.string   "secret"
    t.datetime "expires_at"
    t.boolean  "auto_sharing",   :default => false
    t.boolean  "send_bookmarks", :default => false
  end

  add_index "authentications", ["provider"], :name => "index_authentications_on_provider"
  add_index "authentications", ["uid"], :name => "index_authentications_on_uid"
  add_index "authentications", ["user_id"], :name => "index_authentications_on_user_id"

  create_table "author_list_memberships", :force => true do |t|
    t.integer  "author_list_id"
    t.integer  "author_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "author_list_memberships", ["author_list_id", "author_id"], :name => "index_author_list_memberships_on_author_list_id_and_author_id", :unique => true
  add_index "author_list_memberships", ["author_list_id"], :name => "index_author_list_memberships_on_author_list_id"

  create_table "author_lists", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "author_subscribes", :force => true do |t|
    t.string   "email"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "authors", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "picture"
    t.string   "twitter"
    t.boolean  "human",            :default => true
    t.integer  "raw_engagement"
    t.integer  "engagement"
    t.integer  "readthrough"
    t.integer  "sample_size"
    t.string   "language"
    t.integer  "average_time"
    t.integer  "sample_diversity"
    t.integer  "average_words"
    t.integer  "primary_site_id"
    t.integer  "articles_count"
    t.string   "email"
  end

  add_index "authors", ["average_time"], :name => "index_authors_on_average_time"
  add_index "authors", ["engagement"], :name => "index_authors_on_engagement"
  add_index "authors", ["language"], :name => "index_authors_on_language"
  add_index "authors", ["name"], :name => "index_authors_on_name"
  add_index "authors", ["raw_engagement"], :name => "index_authors_on_raw_engagement"
  add_index "authors", ["sample_diversity"], :name => "index_authors_on_sample_diversity"
  add_index "authors", ["sample_size"], :name => "index_authors_on_sample_size"

  create_table "authorships", :force => true do |t|
    t.integer  "author_id"
    t.integer  "article_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "authorships", ["article_id"], :name => "index_authorships_on_article_id"
  add_index "authorships", ["author_id", "created_at"], :name => "index_authorships_on_author_id_and_created_at"
  add_index "authorships", ["author_id"], :name => "index_authorships_on_author_id"
  add_index "authorships", ["created_at"], :name => "index_authorships_on_created_at"

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

  create_table "blog_images", :force => true do |t|
    t.integer  "blog_post_id"
    t.string   "name"
    t.string   "image"
    t.string   "title"
    t.string   "source"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.integer  "width"
    t.integer  "height"
  end

  create_table "blog_post_revisions", :force => true do |t|
    t.integer  "blog_post_id", :null => false
    t.text     "body"
    t.integer  "creator_id",   :null => false
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "blog_posts", :force => true do |t|
    t.text     "body"
    t.text     "title"
    t.string   "slug"
    t.datetime "published_at"
    t.integer  "author_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "blog_posts", ["published_at"], :name => "index_blog_posts_on_published_at"
  add_index "blog_posts", ["slug"], :name => "index_blog_posts_on_slug", :unique => true

  create_table "bookmarks", :force => true do |t|
    t.integer  "article_id"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "bookmarks", ["user_id"], :name => "index_article_savings_on_user_id"

  create_table "boolean_feedback", :force => true do |t|
    t.boolean  "positive"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
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

  create_table "concealments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "concealable_id"
    t.string   "concealable_type"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "concealments", ["concealable_id", "concealable_type"], :name => "index_concealments_on_concealable_id_and_concealable_type"
  add_index "concealments", ["user_id"], :name => "index_concealments_on_user_id"

  create_table "conglomerate_ownerships", :force => true do |t|
    t.integer  "conglomerate_id"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.float    "share"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "conglomerates", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "content_experiment_participations", :force => true do |t|
    t.integer  "content_experiment_id"
    t.integer  "user_id"
    t.integer  "choice"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
  end

  add_index "content_experiment_participations", ["content_experiment_id", "user_id"], :name => "cep_on_ceid_and_uid", :unique => true

  create_table "content_experiments", :force => true do |t|
    t.string   "a"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

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
    t.string   "queue"
  end

  add_index "delayed_jobs", ["attempts"], :name => "index_delayed_jobs_on_attempts"
  add_index "delayed_jobs", ["priority", "run_at"], :name => "index_delayed_jobs_on_priority_and_run_at"

  create_table "digest_emails", :force => true do |t|
    t.integer  "user_id"
    t.datetime "opened_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "unsubscribe_token"
    t.datetime "unsubscribed_at"
  end

  add_index "digest_emails", ["created_at"], :name => "index_digest_emails_on_created_at"

  create_table "digest_subscribes", :force => true do |t|
    t.string   "email"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "digest_time_slots", :force => true do |t|
    t.integer  "user_id"
    t.integer  "weekday",                      :null => false
    t.integer  "hour",                         :null => false
    t.boolean  "enabled",    :default => true, :null => false
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
  end

  add_index "digest_time_slots", ["enabled"], :name => "index_digest_time_slots_on_enabled"
  add_index "digest_time_slots", ["user_id"], :name => "index_digest_time_slots_on_user_id"
  add_index "digest_time_slots", ["weekday", "hour"], :name => "index_digest_time_slots_on_weekday_and_hour"

  create_table "email_shares", :force => true do |t|
    t.integer  "article_id"
    t.integer  "user_id"
    t.text     "recipients"
    t.string   "title"
    t.text     "body"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "source"
  end

  create_table "emails", :force => true do |t|
    t.string   "message_type"
    t.integer  "user_id"
    t.datetime "opened_at"
    t.string   "unsubscribe_token"
    t.datetime "unsubscribed_at"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  create_table "experiments", :force => true do |t|
    t.string   "test_name"
    t.string   "status"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "experiments", ["test_name"], :name => "index_experiments_on_test_name"

  create_table "extension_installations", :force => true do |t|
    t.integer  "user_id"
    t.string   "version"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "extension_installations", ["user_id", "version"], :name => "index_extension_installations_on_user_id_and_version", :unique => true
  add_index "extension_installations", ["user_id"], :name => "index_extension_installations_on_user_id"

  create_table "facebook_friendships", :force => true do |t|
    t.integer  "user_id"
    t.integer  "potential_user_id"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "facebook_friendships", ["potential_user_id"], :name => "index_facebook_friendships_on_potential_user_id"
  add_index "facebook_friendships", ["user_id", "potential_user_id"], :name => "index_facebook_friendships_on_user_id_and_potential_user_id", :unique => true

  create_table "facebook_shares", :force => true do |t|
    t.integer  "article_id"
    t.integer  "user_id"
    t.string   "share_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "source"
  end

  create_table "feedback_messages", :force => true do |t|
    t.integer  "user_id"
    t.text     "message"
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
    t.boolean  "invited"
  end

  add_index "friendships", ["user_id", "friend_id"], :name => "index_friendships_on_user_id_and_friend_id", :unique => true

  create_table "group_memberships", :force => true do |t|
    t.integer  "group_id"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "group_memberships", ["group_id"], :name => "index_group_memberships_on_group_id"

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "history_items", :force => true do |t|
    t.integer  "user_id"
    t.text     "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "article_id"
  end

  create_table "html_documents", :force => true do |t|
    t.integer  "article_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "cached_file"
  end

  add_index "html_documents", ["article_id"], :name => "index_html_documents_on_article_id"

  create_table "invitations", :force => true do |t|
    t.integer  "user_id"
    t.string   "email"
    t.datetime "opened_at"
    t.integer  "single_use_invite_id"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.text     "message"
  end

  create_table "invite_requests", :force => true do |t|
    t.integer  "user_id"
    t.string   "state",      :default => "requested"
    t.string   "secret"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
  end

  create_table "issue_articles", :force => true do |t|
    t.integer "issue_id"
    t.integer "article_id"
  end

  add_index "issue_articles", ["issue_id"], :name => "index_issue_articles_on_issue_id"

  create_table "issues", :force => true do |t|
    t.integer  "user_id"
    t.datetime "created_at", :null => false
  end

  add_index "issues", ["user_id", "created_at"], :name => "index_issues_on_user_id_and_created_at"

  create_table "json_caches", :force => true do |t|
    t.string   "key"
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "json_caches", ["key"], :name => "index_json_caches_on_key"

  create_table "mass_invites", :force => true do |t|
    t.string   "secret"
    t.boolean  "enabled",    :default => true
    t.integer  "limit"
    t.datetime "expires_at"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.text     "inviter"
    t.boolean  "anonymous"
  end

  create_table "media_references", :force => true do |t|
    t.integer  "article_id"
    t.integer  "site_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "media_references", ["article_id"], :name => "index_media_references_on_article_id"
  add_index "media_references", ["site_id"], :name => "index_media_references_on_site_id"

  create_table "notifications", :force => true do |t|
    t.integer  "user_id"
    t.integer  "reason_id"
    t.string   "reason_type"
    t.string   "state",       :default => "new"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "subject_id"
  end

  create_table "password_requests", :force => true do |t|
    t.integer  "user_id"
    t.text     "secret"
    t.datetime "expires_at"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "people", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "potential_users", :force => true do |t|
    t.string   "name"
    t.string   "uid"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.integer  "friends_count"
  end

  add_index "potential_users", ["uid"], :name => "index_potential_users_on_uid"

  create_table "reader_relationships", :force => true do |t|
    t.integer  "user_id"
    t.integer  "source_id"
    t.string   "source_type"
    t.integer  "total_time"
    t.integer  "solicited_time"
    t.integer  "total_reads"
    t.integer  "solicited_reads"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "weight",          :default => 0.0
    t.float    "favoritism",      :default => 0.0
  end

  add_index "reader_relationships", ["user_id", "source_id", "source_type"], :name => "user_source"

  create_table "recommendations", :force => true do |t|
    t.integer  "user_id"
    t.integer  "article_id"
    t.string   "state"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rss_feeds", :force => true do |t|
    t.string   "url"
    t.string   "tag"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "site_id"
  end

  add_index "rss_feeds", ["site_id"], :name => "index_rss_feeds_on_site_id"

  create_table "scraping_rules", :force => true do |t|
    t.integer  "site_id"
    t.string   "element_type"
    t.text     "rule"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "scraping_rules", ["site_id"], :name => "index_scraping_rules_on_site_id"

  create_table "sections", :force => true do |t|
    t.integer  "site_id"
    t.string   "url"
    t.boolean  "blacklisted"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "language"
  end

  add_index "sections", ["site_id"], :name => "index_sections_on_site_id"

  create_table "single_use_invites", :force => true do |t|
    t.integer  "inviter_id"
    t.integer  "user_id"
    t.string   "secret"
    t.string   "state"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "single_use_invites", ["inviter_id"], :name => "index_single_use_invites_on_inviter_id"
  add_index "single_use_invites", ["secret"], :name => "index_single_use_invites_on_secret"

  create_table "site_relatednesses", :force => true do |t|
    t.integer  "source_id"
    t.integer  "target_id"
    t.float    "relatedness"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "reverse"
    t.float    "mutual"
  end

  add_index "site_relatednesses", ["source_id", "target_id"], :name => "index_site_relatednesses_on_source_id_and_target_id"
  add_index "site_relatednesses", ["source_id"], :name => "index_site_relatednesses_on_source_id"
  add_index "site_relatednesses", ["target_id"], :name => "index_site_relatednesses_on_target_id"

  create_table "site_visit_counts", :force => true do |t|
    t.integer  "user_id"
    t.integer  "site_id"
    t.integer  "count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sites", :force => true do |t|
    t.string   "url"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "articles_count", :default => 0
    t.string   "state"
    t.string   "language"
    t.integer  "suggester_id"
    t.string   "country"
    t.string   "twitter"
  end

  add_index "sites", ["url"], :name => "index_sites_on_url"
  add_index "sites", ["url"], :name => "unique_site_url", :unique => true

  create_table "social_shares", :force => true do |t|
    t.integer  "article_id"
    t.integer  "user_id"
    t.text     "body"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.integer  "authentication_id"
    t.string   "share_id"
  end

  create_table "statistics", :force => true do |t|
    t.string   "name"
    t.date     "date"
    t.integer  "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "statistics", ["name", "date"], :name => "index_statistics_on_name_and_date"

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

  add_index "tag_predictions", ["article_id"], :name => "index_tag_predictions_on_article_id"

  create_table "tags", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "parameter"
    t.integer  "supertag_id"
    t.datetime "recalculated_at",                 :default => '2011-08-17 10:21:34'
    t.integer  "new_data_since_recalculated",     :default => 0
    t.float    "hotness",                         :default => 0.0
    t.integer  "illustrating_article_id"
    t.datetime "illustrating_article_updated_at", :default => '2012-01-03 09:46:57'
  end

  create_table "testimonials", :force => true do |t|
    t.string   "statement"
    t.string   "source"
    t.string   "url"
    t.string   "language"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "image_url"
  end

  create_table "timeline_shares", :force => true do |t|
    t.integer  "authentication_id"
    t.string   "share_url"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  create_table "token_frequencies", :force => true do |t|
    t.integer  "token_id"
    t.integer  "tag_id"
    t.integer  "count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "token_frequencies", ["tag_id"], :name => "index_token_frequencies_on_tag_id"
  add_index "token_frequencies", ["token_id"], :name => "index_token_frequencies_on_token_id"

  create_table "tokens", :force => true do |t|
    t.string   "name"
    t.integer  "count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "genericity"
  end

  add_index "tokens", ["name"], :name => "index_tokens_on_name"

  create_table "twitter_shares", :force => true do |t|
    t.integer  "article_id"
    t.integer  "user_id"
    t.integer  "authentication_id"
    t.string   "share_id"
    t.text     "body"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.string   "source"
  end

  create_table "user_analytics_items", :force => true do |t|
    t.integer "user_id"
    t.text    "referrer"
    t.text    "entry_point"
    t.integer "tweet_referrer_id"
    t.integer "mass_invite_id"
    t.integer "invitation_id"
    t.text    "user_agent"
    t.boolean "chrome",            :default => false
    t.boolean "firefox",           :default => false
  end

  add_index "user_analytics_items", ["user_id"], :name => "index_user_analytics_items_on_user_id"

  create_table "user_compatibilities", :force => true do |t|
    t.integer  "user_a_id"
    t.integer  "user_b_id"
    t.float    "compatibility"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "user_compatibilities", ["user_a_id", "user_b_id"], :name => "index_user_compatibilities_on_user_a_id_and_user_b_id"

  create_table "user_languages", :force => true do |t|
    t.integer  "user_id"
    t.string   "language"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "blacklisted", :default => false
    t.boolean  "greylisted",  :default => false
    t.float    "weight"
  end

  add_index "user_languages", ["user_id"], :name => "index_user_languages_on_languages"
  add_index "user_languages", ["user_id"], :name => "index_user_languages_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "login"
    t.string   "email",                                     :null => false
    t.string   "crypted_password",                          :null => false
    t.string   "password_salt",                             :null => false
    t.string   "persistence_token",                         :null => false
    t.string   "single_access_token",                       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "friends_updated_at"
    t.datetime "extension_installed_at"
    t.string   "gender"
    t.string   "hometown"
    t.string   "location"
    t.string   "locale"
    t.date     "birthday"
    t.boolean  "anonymous",              :default => false, :null => false
    t.integer  "friendships_count",      :default => 0
    t.boolean  "authenticated",          :default => false
    t.boolean  "unsubscribed",           :default => false
    t.datetime "languages_updated_at"
    t.integer  "tweet_referrees_count",  :default => 0
    t.datetime "signup_completed_at"
    t.integer  "visits_count"
    t.string   "abingo_identity"
    t.datetime "last_vote_at"
  end

  add_index "users", ["abingo_identity"], :name => "index_users_on_abingo_identity"
  add_index "users", ["anonymous"], :name => "index_users_on_anonymous"
  add_index "users", ["email"], :name => "index_users_on_email_where_not_anonymous"
  add_index "users", ["email"], :name => "index_users_on_login_where_not_anonymous"
  add_index "users", ["persistence_token"], :name => "index_users_on_persistence_token"
  add_index "users", ["single_access_token"], :name => "index_users_on_single_access_token"

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
    t.boolean  "referred_by_scoopinion"
    t.string   "ip_address"
    t.text     "heatmap"
    t.integer  "history_item_id"
    t.integer  "progress"
  end

  add_index "visits", ["article_id", "user_id"], :name => "index_visits_on_article_id_and_user_id"
  add_index "visits", ["created_at"], :name => "index_visits_on_created_at"
  add_index "visits", ["referred_by_scoopinion"], :name => "index_visits_on_referred_by_scoopinion"
  add_index "visits", ["user_id", "created_at"], :name => "index_visits_on_user_id_and_created_at"

  create_table "whitelist_votes", :force => true do |t|
    t.string   "voter_id"
    t.string   "url"
    t.integer  "votes"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

end
