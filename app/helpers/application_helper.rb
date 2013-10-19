module ApplicationHelper
  
  def language_codes_for_select
    require "language_standard"
    LanguageStandard.as_json.map{|a| [ a[:name], a[:code] ] }.sort_by{ |a| a[0] }
  end
  
  def app_view?
    params[:controller] == "feeds"
  end

  def landing?
    params[:controller] == "landing" || params[:controller] == "author_insights"
  end

  def show_flash
    [:notice, :error, :alert].map { |level|
      unless flash[level].blank?
        content_tag :div, class: "flash-message #{level.to_s}" do
          content_tag :p, flash[level]
        end
      end
    }.compact.reduce(:<<)
  end

  def localized_asset_path(file)
    prefix = ""
    prefix = "fi/" if locale.to_s == "fi"
    asset_path(prefix + file)
  end
  
  def html_class(options)
    logged = current_user ? "logged" : "not-logged"
    admin = admin? ? "admin" : "no-admin"
    [params[:controller].parameterize, params[:action], params[:page], params[:subpage], logged, locale, admin, options[:extra]]
      .compact.reject { |a| a.empty? }.join(" ")
  end
  
  def title(page_title, options = { })
    page_title ||= ""
    content_for(:og_title) { page_title } unless options[:separate_og_title]
    html_title = page_title
    html_title = html_title + " | Scoopinion" unless options[:complete]
    content_for(:title) { html_title }
  end

  def heading(page_heading)
    content_for(:heading) { page_heading }
  end
  
  def markdown(input)
    input ||= ""
    Redcarpet::Markdown.new(Redcarpet::Render::HTML.new).render(input).html_safe
  end
  
  def description(page_description)
    content_for(:description) { page_description }
  end
  
  def thumbnail(page_thumbnail)
    return unless page_thumbnail
    page_thumbnail = "https://www.scoopinion.com" + page_thumbnail if Rails.env.production? && !page_thumbnail.start_with?("http")
    content_for(:thumbnail) { page_thumbnail }
  end
  
  def default_title
    t("opengraph.title")
  end
  
  def default_description
    t("opengraph.description")
  end
  
  def subdomain
    return "fb" if request.host == "scoopinion.heroku.com"
    request.host.split(".")[0]
  end

  def authentication_path(provider, options={ })
    "/auth/#{provider.to_s}"
  end
  
  def pretty_seconds(seconds)
    return "" unless seconds
    minutes = ""
    minutes = "#{seconds.floor / 60} min" if seconds > 59
    remainder = seconds.floor % 60
    seconds = remainder > 0 ? "#{seconds.floor % 60} s" : ""
    space = (minutes.empty? || seconds.empty?) ? "" : " "
    "#{minutes}#{space}#{seconds}"
  end
  
  def comma_delimit(array)
    if array.size > 1
      and_join = "#{array[-2]} and #{array[-1]}"
      array = array[0..-3] + [ and_join ]
    end
    array.join(", ")
  end
  
  def round_to(number, accuracy)
    return number if number < accuracy
    (number / accuracy).round * accuracy
  end
  
  def this_or_default(this, default)
    this.empty? ? default : this
  end
  
  def html_entities(text)
    strip_tags(text).try(:html_safe)
  end
  
  def cache_token(validity)
    
    date = Time.now.to_date.to_datetime
    elapsed = Time.now - date
    
    [ date, elapsed.to_i / validity ]
    
  end

  def appId
    if Rails.env.development? or Rails.env.staging?
      "235977853087936" 
    else
      "158838614188764"
    end
  end
  
  def counter_data
    Rails.cache.fetch("counter_data_v4", :expires_in => 3.hours) do
      { 
        "data-count" => Visit.count,
        "data-delay" => [ 1.hour, 24.hours, 1.week ].map{ |period | (1000 * period / Visit.where{ created_at > Visit.maximum(:created_at) - period }.count.to_f).to_i }.min,
        "data-since" => Time.now.getutc.to_i
      }
    end
  end
  
  def with_format(format, &block)
    old_format = self.formats
    self.formats = Array.wrap format
    result = block.call
    self.formats = old_format
    return result
  end
  
  def chrome_web_store_url
    "https://chrome.google.com/webstore/detail/cojhbmpnoehchagcbojelmclgjgopilf"
  end
  
  def chrome_web_store_review_url
    chrome_web_store_url + "/reviews"
  end
  
  def user_questionnaire_url
    "https://docs.google.com/spreadsheet/viewform?formkey=dFAwOF96ZzhZWXlrMkpVNzd3cXNGamc6MQ&theme=0AX42CRMsmRFbUy0yMjdiMTQ4Yi0zZjUwLTQ5NTUtOGVmNC05ODNlZTUxYTViYzA&ifq"
  end

  def twitter_follow_button(username, options = {})
    return nil unless username
    options = {
      class: "twitter-follow social__item socialite",
      "data-show-count" => "false"
    }.merge(options)
    link_to "Follow", "https://twitter.com/#{username}", options
  end

  def twitter_tweet_button(url = nil, options = {})
    default_options = {
      class: "twitter-share social__item socialite",
      "data-count" => "none",
    }
    default_options.merge!("data-url" => url) if url
    link_to "Tweet", "http://twitter.com/share", default_options.merge(options)
  end

  def fb_like_button(url = nil, options = {})
    default_options = {
      class: "facebook-like social__item socialite",
      "data-send" => "false", 
      "data-width" => "100", 
      "data-layout" => "button_count", 
      "data-show-faces" => "false", 
      "data-font" => "arial",
    }
    default_options.merge!("data-href" => url) if url
    link_to "Like us on Facebook", "http://www.facebook.com/sharer.php?u=#{url}", default_options.merge(options)
  end

  def profile_image_tag(user)
    if user.profile_pic.present?
      image_tag(user.profile_pic(width: 100, height: 100), alt: "Profile Picture", size: "100x100")
    elsif user.respond_to?(:primary_site) && user.primary_site
      profile_image_tag(user.primary_site)
    else
      content_tag :div, nil, class: "profile-placeholder"   
    end
  end

  def fb_connect_button(state = nil)
    link_to I18n.t(:facebook_connect, scope: "users.new"), 
    {                                                      
      controller: "authentications",                       
      action: "create",                                    
      provider: :facebook,                                 
      state: state,                           
    },                                                     
    {                                                      
      class: "connect-button-facebook"                     
    }
  end
    
  def add_first_or_last(index, collection)
    return "first" if index == 0
    return "last" if index == collection.count - 1
  end
  
  def truncate_url(url)
    truncate(url.gsub("www.", "").gsub(/https?:\/\//, ""), :length => 30)
  end
  
  def beautify_entry_point(url)
    url = url.gsub("www.", "").gsub(/https?:\/\//, "").gsub("scoopinion.com", "")
    url = "Chrome Web Store" if url == "/users/current.json"    
    url
  end
  
  def app_status(user)
    return "app" if user.extension_installed_at
    return "<span title=\"#{h user.user_analytics_item.user_agent}\">n/a</span>".html_safe if user.user_analytics_item && !(user.user_analytics_item.firefox || user.user_analytics_item.chrome)
    return ""
  end

  def nav_link(link_text, link_path, selection_restraints = {})
    # current_page?() does not work with a hash for some reason
    class_name = selection_restraints[:controller] == controller_name ? "is-selected" : nil

    content_tag(:li, :class => class_name) do
      link_to link_text, link_path
    end
  end

end
