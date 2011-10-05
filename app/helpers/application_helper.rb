module ApplicationHelper
  
  def html_class(options)
    options[:extra] ||= ""
    [params[:controller].parameterize, params[:action], params[:page], subdomain, options[:extra]].compact.join(" ")
  end
  
  def title(page_title)
    content_for(:title) { page_title + " | Scoopinion"}
  end
  
  def description(page_description)
    content_for(:description) { page_description }
  end
  
  def thumbnail(page_thumbnail)
    content_for(:thumbnail) { page_thumbnail }
  end

  def default_description
    "Scoopinion is an effortless community-based news recommendation and spreading service. It's the easiest way to know what your friends have read and you haven't."
  end
  
  def subdomain
    return "fb" if request.host == "scoopinion.heroku.com"
    request.host.split(".")[0]
  end

  def authentication_path(provider)
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
  
  def truncate(text, options={ })
    limit = options[:limit] || 300
    
    
    return "" unless text
    return text if text.length < limit
    
    text = text[0..limit].split(" ")[0..-2].join(" ")
    if not text[-1] =~ /[.,?!]/
      text = text + "..."
    end
  end
  
  def cache_token(validity)
    
    date = Time.now.to_date.to_datetime
    elapsed = Time.now - date
    
    [ date, elapsed.to_i / validity ]
    
  end
  
end
