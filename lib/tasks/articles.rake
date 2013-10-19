desc "fetches site languages"
namespace :article do
  
  task :update_finders => :environment do
    Article.where("finder_id IS NULL").order("created_at DESC").each do |a|
      a.finder_id = a.visits.first.try(:user_id)
      a.save
      p a.id
    end
  end
  
  task :recalculate_last_week => :environment do
    index = 0
    to_update = Article.newer_than(1.week)
    to_update.find_in_batches do |articles| 
      articles.each do |a|
        a.delay.recalculate! 
      end
      index = index + articles.count
      p "#{index} / #{to_update.count}"
    end
  end
  
  
  task :recalculate_newest => :environment do
    Article.newer_than(1.day).order("created_at DESC").find_each{ |a| a.recalculate! }
  end

  task :recalculate_visits => :environment do
    Visit.where("created_at > ?", Time.now - 7.days).each do |v|
      p v
      v.save
    end
  end
  
  task :migrate_old_html => :environment do
    Article.where("raw_html is not null").select{ |a| a.html_document == nil}.find_each(:batch_size => 10) do |a| 
      a.delay.migrate_old_html
      sleep 10
    end
  end

  task :recalculate_all => :environment do
    Article.order("created_at desc").find_each { |a| a.delay.recalculate! }
  end
  
  task :migrate_raw_html_to_s3 => :environment do
    HtmlDocument.order("created_at desc").where("cached_file is null").find_each { |x| x.delay(:priority => -1).migrate_raw_to_s3! }
  end
  
  task :merge_duplicates => :environment do
    Article.delete_or_merge_duplicates
  end
  
end

