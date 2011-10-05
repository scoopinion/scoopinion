desc "fetches site languages"
namespace :articles do
  
  task :update_finders => :environment do
    Article.where("finder_id IS NULL").order("created_at DESC").each do |a|
      a.finder_id = a.visits.first.try(:user_id)
      a.save
      p a.id
    end
  end
  
  task :recalculate_scores => :environment do
    Article.newer_than(7.days).find_each{ |a| p a; a.recalculate! }
  end
  
  
  task :recalculate_newest => :environment do
    Article.newer_than(1.day).order_by("created_at DESC").find_each{ |a| p a; a.recalculate! }
  end

  task :recalculate_visits => :environment do
    Visit.where("created_at > ?", Time.now - 7.days).each do |v|
      p v
      v.save
    end
  end
  
  
end

