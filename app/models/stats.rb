class Stats
  
  def self.new_users
    make_stats(User.where("id NOT IN (?)", User::TEAM_IDS))
  end
  
  def self.visits
    make_stats(Visit.where("user_id NOT IN (?)", User::TEAM_IDS))
  end
  
  def self.articles
    make_stats(Article.all)
  end
  
  def self.article_click_through
    make_stats(Visit.where("referrer like '%scoopinion.com%'").where("user_id NOT IN (?)", User::TEAM_IDS))
  end
  
  def self.new_extensions
    make_stats(User.where("id NOT IN (?)", User::TEAM_IDS).select{ |u| u.visits.any? })
  end
  
  def self.comments
    make_stats(Comment.where("user_id NOT IN (?)", User::TEAM_IDS))
  end
  
  
  def self.cumulative_summary
    [
     [ "Accounts", User.where("id NOT IN (?)", User::TEAM_IDS) ],
     [ "Extensions", User.where("id NOT IN (?)", User::TEAM_IDS).select{ |u| u.visits.any? } ],
     [ "Visits", Visit.where("user_id NOT IN (?)", User::TEAM_IDS) ],
     [ "Articles", Article.all ],
     [ "Comments", Comment.where("user_id NOT IN (?)", User::TEAM_IDS) ],
    ]
  end

  
  private
  
  def self.make_stats(query)
    stats = query.group_by{ |p| p.created_at.at_beginning_of_day }.to_a
    stats.sort_by!{ |a| a[0] }
    stats = fill_zeros(stats)
    stats.sort_by{ |a| a[0] }.reverse[0..20]
  end
  
  def self.fill_zeros(stats)
    missing = []
    stats[0..-2].each_with_index do |array, index|
      missing_days = ((stats[index+1][0] - array[0]) / 86400) - 1
      missing_days.to_i.times do |i|
        missing << [ array[0] + (i+1) * 86400, []]
      end
    end
    stats + missing
  end
  
end
