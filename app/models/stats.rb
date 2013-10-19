class Stats

  def self.span
    @period || 120
  end
  
  def self.span=(p)
    @period = p
  end
    
  def self.epoch
    Time.now
  end
  
  def self.cache_stats(name)
    stats = Statistic.where(name: name).where{ date >= my { self.epoch - (self.span+1).days } }.order("date asc").group_by{ |x| x.date.to_s }
    Range.new(1, self.span).to_a.reverse.map do |day|
      key = (self.epoch.getutc.to_date - day.days).to_date.to_s
      stat = 
        stats[key].try(:first) ||
        Statistic.create(:name => name, :date => key, :value => yield(day - 1))
      [ self.epoch.getutc.beginning_of_day - day.days, stat.value ]
    end.reverse
  end
  
  def self.all
    [
     [ "Growth", "(% new signups last week vs. readers the previous week)", :growth],
     [ "New signups", "(Weekly / Daily)", :new_signups ],
     [ "Data collected", "(Monthly / Weekly / Daily)", :data_collected ],
     [ "Active addons", "(Monthly / Weekly / Daily)", :active_addons ],
     [ "Active signed-up readers", "(at least 3 stories, Monthly / Weekly / Daily)", :weekly_active_readers ],
     [ "Active signed-up readers", "(at least 1 story, Monthly / Weekly / Daily)", :weekly_readers ],
     [ "Weekly new user engagement", "(per mil, at least 1 / 3 / 7 stories)", :new_user_engagement ],
     [ "Active user count", "(Monthly / Weekly / Daily, at least 1 story read, or email opened)", :user_count ],
     [ "Weekly extension loss rate", "(percent)", :weekly_extension_loss_rate ],
     [ "Weekly reader loss rate", "(per mil)", :weekly_reader_loss_rate ],
     [ "Articles Shared", "(Weekly, Total / Facebook / Twitter / Email)", :articles_shared ],
     [ "Total referred reading time", "(hours, Monthly / Weekly / Daily)", :total_referred_time ],
     [ "Referred articles", "(Monthly / Weekly / Daily)", :refer_count ],
     [ "Median refer length", "(Weekly, seconds)", :weekly_median_refer_length ],
     [ "Invitations sent", "(Weekly)", :invitations_sent, [ 7 ] ],
     [ "Invitations accepted after a week", "(Weekly, per mil)", :invitations_accepted, [ 7 ] ],
     [ "Emails opened (lower bound)", "(Weekly, after a week, per mil)", :emails_opened, [ 7 ] ],
     [ "Email click-through (at least one)", "(Weekly, per mil)", :email_click_through, [ 7 ] ],
     [ "Email article click through", "(Weekly, per mil)", :email_article_click_rate, [ 7 ] ],
     [ "Email unsubscriptions", "(Weekly, percent * 100)", :email_unsubscriptions, [ 7 ] ],
     [ "Finnish vs. English", "(Weekly, seconds)", :finnish_vs_english ],
     [ "Other languages", "(Weekly, number of users)", :other_languages ],
     [ "Feedback amout", "(Weekly)", :feedback_amount ],
     [ "Feedback tone", "(Weekly, percent positive)", :feedback_tone ]
     
    ].map{ |x| Hash[[ :title, :description, :method, :args ].zip(x)] }
  end
  
  def self.cache_all
    self.all.each do |s|
      puts s[:method]
      self.send(s[:method], *s[:args])
    end
  end
  
  def self.period(relation, day, length)
    relation.where{ (created_at < my { (self.epoch.getutc.beginning_of_day - day.days) }) & (created_at > my { (self.epoch.getutc.beginning_of_day - (day + length).days) }) }
  end
  
  def self.delimit(options={ })
    self.period(options[:relation], options[:days_ago], options[:days_back])
  end
  
  def self.growth
    g = self.cache_stats("growth v2") do |day|
      active_readers = active_readers_in_period(day + 7, 7, 1)
      if active_readers.count.zero?
        0
      else
        new_signups = period(User, day, 7).normal.pluck(:id)
        1000 * (new_signups.count.to_f / active_readers.count)
      end
    end.map{ |a| [a[0], a[1] / 10.0]}
    goal = g.map{ |a| [ a[0], 25 ]}
    collapse([ g, goal ])
  end
  
  def self.new_signups
    collapse([ 1, 7 ].map do |num|
               self.cache_stats("new signups #{num}") do |day|
                 period(User.normal, day, num).select("count(*)").first.count.to_i
               end
             end)
  end
  
  def self.weekly_extension_loss_rate
    self.cache_stats("weekly_extension_loss_rate_v3") do |day|
      back = period(Visit.unsolicited, day + 7, 7).select("DISTINCT(user_id)").pluck(:user_id)
      front = period(Visit.unsolicited, day, 7).select("DISTINCT(user_id)").pluck(:user_id)
      100 - 100 * (back & front).count.to_f / back.count
    end
  end
  
  def self.weekly_reader_loss_rate
    self.cache_stats("weekly_reader_loss_rate v5") do |day|
      back = self.active_readers_in_period(day + 7, 7)
      front = self.active_readers_in_period(day, 7, 1)
      1000 - 1000 * (back & front).count.to_f / back.count
    end
  end

  def self.data_collected
    cache_key = "data_collected v4"
    collapse([ 1, 7, 28 ].map do |num|
               self.cache_stats("#{num} #{cache_key}") do |day|
                 rolling_cache(cache_key, day, num) do |day, num|
                   period(Visit, day, num).count
                 end
               end
             end
             )
  end
  
  def self.cache_key(name, day, period)
    "#{name} #{self.epoch.getutc.beginning_of_day - day.days} #{period}"
  end

  
  def self.rolling_cache(name, day, num, &block)
    
    key = cache_key(name, day, num)
    
    if Rails.cache.exist?(key)
      return Rails.cache.read(key)
    end
    
    if num == 1
      result = yield(day, num)
    else
      new_key = cache_key(name, day + 1, num)
      if Rails.cache.exist?(new_key)
        result = rolling_cache(name, day+1, num, &block) + rolling_cache(name, day, 1, &block) - rolling_cache(name, day + num, 1, &block)
      else
        result = yield(day, num)
      end         
    end
    
    Rails.cache.write(key, result)
    
    return result
  end
  
  def self.collapse(series)
    return series unless series.length > 0
    series[0].map{|x|x[0]}.zip(series.map{|x|x.map{|y|y[1]}}.transpose)
  end
  
  def self.finnish_vs_english
    collapse(
              [ "fi", "en" ].map do |la|
               self.cache_stats("languages_#{la}_v3") do |day|
                 self.rolling_cache("#{la} v3", day, 7) do |day, num|
                   period(Visit.unsolicited, day, num).joins(:article).where{ article.language == la }.sum(:total_time)
                 end
                end
              end
              )
  end

  
  def self.other_languages
    collapse((recent_languages.map{|x| x[0..1] }.uniq - ["fi", "en"]).map do |la| 
               self.cache_stats("languages_#{la}_v5") do |day|
                 period(Visit.unsolicited, day, 7).joins(:article).where{ article.language == la }.select("DISTINCT(user_id)").count
               end
             end)
  end
    
  def self.weekly_eyeballs_to_signups
    self.cache_stats("weekly_signups_to_eyeballs_v3") do |day|
      eyeballs = period(User, day, 7).where("created_at > ?", Date.parse("2011-11-26")).where("anonymous = ? OR email != ''", true).count
      signups = period(User, day, 7).where("created_at > ?", Date.parse("2011-11-26")).where(:anonymous => false).count
      
      if eyeballs > 0
        1000 * signups.to_f / eyeballs
      else
        0
      end
      
    end
  end
  
  def self.weekly_median_refer_length
    self.cache_stats("weekly_median_refer_length") do |day|
      refs = period(Visit, day, 7).solicited.where{ total_time < 1000 }.order(:total_time)
      refs[refs.count / 2].try(:total_time) || 0
    end
  end
  
  def self.refer_count
    collapse([ 1, 7, 28 ].map do |num|
               self.cache_stats("refer_count #{num}") do |day|
                 self.rolling_cache("refer_count v2", day, num) do |day, num|
                   period(Visit, day, num).solicited.count
                 end
               end
             end)
  end
  
  def self.total_referred_time
    collapse(
             [ 1, 7, 28 ].map do |num|
               self.cache_stats("total_referred_time #{num} v3") do |day|
                 self.rolling_cache("referred_time v4", day, num) do |day, num|
                   period(Visit, day, num).solicited.where{ total_time < 1000 }.sum(:total_time) / 60 / 60
                 end
               end
             end
            )
  end
  
  def self.emails_opened(period)
    ([[ 0, false ]] * 7) + self.cache_stats("emails_opened_v2_#{period}_v6") do |day|
      emails = delimit(relation: DigestEmail, days_ago: day + 7, days_back: period)
      
      only_clicked = emails.where{ opened_at == nil }.joins(:article_mailings).where("article_mailings.clicked_at IS NOT NULL").pluck("digest_emails.id").uniq.count
      
      1000 * (emails.opened.count + only_clicked) / emails.count.to_f
    end[0..-8]
  end
  
  def self.invitations_sent(period)
    self.cache_stats("invitations_sent_#{period}_v2") do |day|
      self.period(Invitation, day, period).count
    end
  end
  
  def self.invitations_accepted(period)
    ([[ 0, false ]] * 7) + self.cache_stats("invitations_accepted_v3") do |day|
      1000 * self.period(Invitation, (day + 7), period).instance_eval { accepted.count / count.to_f }
    end[0..-8]
  end
  
  def self.shift_back(stats, days)
    ([[ 0, false ]] * days) + stats[0..-(days+1)]
  end

  
  def self.email_click_through(period)
    shift_back(self.cache_stats("emails_click_through_#{period}_v6") do |day|
      10 * period(DigestEmail, day + 7, period).percent{ joins(:article_mailings).where("article_mailings.clicked_at IS NOT NULL").select("DISTINCT(digest_emails.id)") }
    end, 7)
  end
  
  def self.email_article_click_rate(period)
    shift_back(self.cache_stats("email_article_click_rate_#{period}_v3") do |day|
      10 * period(ArticleMailing, day + 7, period).percent{ where{ clicked_at != nil } }
    end, 7)
  end
  
  def self.email_unsubscriptions(period)
    self.cache_stats("email_unsubscriptions_#{period} v3") do |day|
      100 * period(DigestEmail, day + 7, period).percent{ unsubscribed }
    end        
  end
  
  
  def self.new_user_engagement
    collapse(
             [ 1, 3, 7 ].map do |num|
               (([ [ 0, false ] ] * 7) + self.cache_stats("new user engagement #{num} v9") do |day|
                 period = 7
                 users = period(User.normal, day + period, period)
                 actives = users.select{ |x| x.visits.solicited.where{ visits.created_at < x.created_at + period.days }.count >= num }.count
                 1000 * (actives.to_f / users.count)
               end)[0..-8] 
             end)
  end
  
  def self.active_readers_in_period(day, period, minimum = 3)
    mail = period(ArticleMailing, day, period).where{ clicked_at != nil }.group_by(&:user_id)
    other = period(Visit.solicited, day, period).joins(:user).where{ user.email != ""}.group_by(&:user_id)
    
    all = { }
    
    mail.each{ |x,y| all[x] = y.count }
    other.each{ |x,y| all[x] = (all[x] || 0) + y.count}
    
    all.reject{ |x,y| y < minimum }.keys
  end
  
  def self.weekly_active_readers
    collapse([ 1, 7, 28 ].map do |num|
               self.cache_stats("active readers #{num} v2") do |day|
                 self.active_readers_in_period(day, num).count
               end
             end)
  end
  
  def self.weekly_readers
    collapse([ 1, 7, 28 ].map do |num|
               self.cache_stats("readers #{num} v2") do |day|
                 self.active_readers_in_period(day, num, 1).count
               end
             end)
  end

  def self.active_addons
    collapse([ 1, 7, 28 ].map do |num|
               self.cache_stats("active collectors #{num} v2") do |day|
                 period(Visit.unsolicited, day, num).select("DISTINCT(user_id)").count
               end
             end)
  end
  
  def self.monthly_active_users(time = Time.now)
    day = 1
    num = 30
    (period(Visit, day, num).joins(:user).solicited.where{ (user.anonymous == false) }.select("DISTINCT(user_id)").pluck(:user_id) |
     period(DigestEmail.opened, day, num).select("DISTINCT(user_id)").pluck(:user_id)).count
  end
  
  def self.user_count
    collapse([ 1, 7, 28 ].map do |num|
               self.cache_stats("user_count #{num} v5") do |day|
                 (period(Visit, day, num).joins(:user).solicited.where{ (user.anonymous == false) }.select("DISTINCT(user_id)").pluck(:user_id) |
                   period(DigestEmail.opened, day, num).select("DISTINCT(user_id)").pluck(:user_id)).count
               end
             end)
  end
  
  def self.articles_shared
    collapse(
             %w(total facebook twitter email).map do |source|
               self.send("#{source}_shared")
             end
             )
  end
  
  def self.total_shared
    self.cache_stats("total_shared v5") do |day|
      period(FacebookShare, day, 7).count + period(TwitterShare, day, 7).count + period(EmailShare, day, 7).count
    end
  end
  
  def self.facebook_shared
    self.cache_stats("facebook_shared v4") do |day|
      period(FacebookShare, day, 7).count
    end
  end
  
  def self.twitter_shared
    self.cache_stats("twitter_shared v4") do |day|
      period(TwitterShare, day, 7).count
    end
  end
  
  def self.email_shared
    self.cache_stats("email_shared v4") do |day|
      period(EmailShare, day, 7).count
    end
  end

  def self.feedback_amount
    self.cache_stats("feedback v4") do |day|
      period(BooleanFeedback, day, 7).count
    end
  end
  
  def self.feedback_tone
    self.cache_stats("feedback positive") do |day|
      period(BooleanFeedback, day, 7).instance_eval{ where(positive: true).count / count.to_f rescue 0 } * 100
    end
  end  
  
  def self.extension_cohort
    cohort_analysis do |a, b, c, d|
      Rails.cache.fetch(["extension cohort v5", a, b, c, d]) do
        self.extensions_active(a, b, c, d)
      end
    end
  end
  
  def self.reader_cohort
    cohort_analysis do |a, b, c, d|
      Rails.cache.fetch(["reader cohort v6", a, b, c, d]) do
        self.readers_active(a, b, c, d)
      end
    end
  end
  
  def self.extensions_active(newer_than, older_than, period_start, period_end)
    
    all = newer_older(User.normal, newer_than, older_than)
    
    100 * newer_older(Visit.unsolicited, period_start, period_end).where{ user_id.in(all) }.pluck(:user_id).uniq.count / all.count.to_f
  end
  
  def self.readers_active(newer_than, older_than, period_start, period_end)
        
    all = newer_older(User.normal, newer_than, older_than)
    
    100 * (newer_older(Visit.solicited, period_start, period_end).where{ user_id.in(all) }.pluck(:user_id) + newer_older(ArticleMailing.clicked, period_start, period_end).where{ user_id.in(all) }.pluck(:user_id)).uniq.count / all.count.to_f
    
  end
  
  def self.usage_frequency
    freqs = User.normal.where{ (signup_completed_at < 2.month.ago) | (signup_completed_at == nil) }.map do |u|
      self.user_usage_frequency(u, 2.months)
    end
    
    [ 0, 7 / 5.0, 7 / 3.0, 7, 30, 60 ].each_cons(2).map do |a, b|
      [ b, freqs.reject{ |x| x == 0 }.select{ |x| x > a && x <= b }.count ]
    end + [ [ 0, freqs.select{ |x| x == 0 }.count ] ]
  end
  
  def self.user_usage_frequency(user, start)
    active_days_count = user.visits.solicited.newer_than(start).map(&:created_at).map{ |x| x.yday + (x.hour / 2 / 100.0)}.uniq.count
    return 0 if active_days_count == 0
    start / (active_days_count.to_f * 1.day)
  end
  
  def self.top_sites(language)
      Site.find_by_sql([ "SELECT sites.id, sum(visits.total_time) 
                            FROM sites
                              INNER JOIN articles ON articles.site_id = sites.id
                              INNER JOIN visits ON articles.id = visits.article_id 
                              WHERE sites.language = ?
                                  AND visits.total_time < 1000
                                  AND visits.referred_by_scoopinion = 't'
                                  AND visits.created_at > ?
                                  GROUP BY sites.id 
                                    ORDER BY sum desc LIMIT 10", language, 3.months.ago ] ).select{ |s| s.sum }.map{ |x| [ Site.find(x.id).name, x.sum ]}
  end
  
  
  def self.top_authors(language)
          Author.find_by_sql([ "SELECT authors.id, sum(visits.total_time) 
                            FROM authors
                              INNER JOIN authorships ON authorships.author_id = authors.id 
                              INNER JOIN articles ON articles.id = authorships.article_id
                              INNER JOIN visits ON articles.id = visits.article_id 
                              WHERE articles.language = ?
                                  AND visits.total_time < 1000
                                  AND visits.referred_by_scoopinion = 't'
                                  AND visits.created_at > ?
                                  GROUP BY authors.id 
                                    ORDER BY sum desc LIMIT 20", language, 3.months.ago ] ).select{ |s| s.sum }.map{ |x| [ Author.find(x.id).name, Author.find(x.id).articles.last.site.name, x.sum ]}
  end
  
  private
  
  def self.recent_languages
    JsonCache.fetch "stats/recent_languages/v2", :expires_in => 1.week do
      Article.newer_than(7.days).select("distinct language").map(&:language).compact.select{ |x| x.length == 2 }
    end
  end
  
  def self.cohort_analysis(&block)
    
    months = (Date.new(2011, 07)..Date.today).select{|d| d.day == 1}
    
    months = months[0..-2].each_with_index.map do |m, i|
      [ m, months[i+1] ]
    end
    
    months.map do |m|
      [ m[0], newer_older(User.normal, m[0], m[1]).count ] + months.select{ |x| x[0] >= m[0] }.map do |m2|
        yield(m[0], m[1], m2[0], m2[1])
      end
    end
    
  end
  
  def self.newer_older(relation, newer, older, table_name = "")
    relation.where("#{table_name}created_at >= ?", newer).where("#{table_name}created_at < ?", older)
  end
  
end
