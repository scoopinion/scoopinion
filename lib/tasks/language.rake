desc "fetches site languages"
namespace :languages do
  
  task :update_sites => :environment do
    Site.where("language IS NULL").each do |s|
      puts "Detecting #{s.title} #{s.url}..."; puts "#{s.guess_language}"
    end
  end
  
  task :update_users => :environment do
    User.find_each do |u|
      puts u.display_name
      puts u.guess_languages!
    end
  end

end
