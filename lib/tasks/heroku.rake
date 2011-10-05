desc "deploys to heroku"
task :heroku_deploy do

  puts "Deploying to scoopinion.com..."

  unless File.directory?(".heroku_cache")
    
    puts "Creating cache..."
    
    `mkdir .heroku_cache`
    `cd .heroku_cache && hg clone ssh://hg@bitbucket.org/villesundberg/huomenet .`
    `cd .heroku_cache && git init && git remote add heroku git@heroku.com:scoopinion.git`
  end
  
  puts `cd .heroku_cache && hg incoming | grep summary`
  puts "Refreshing..."
  `rm -rf .heroku_cache/app/assets`
  puts "hg pull"
  `cd .heroku_cache && hg pull`
  puts "hg up"
  `cd .heroku_cache && hg up -C`
  puts "hg revert ."
  `cd .heroku_cache && hg revert .`
  puts "Purging assets..."
  `rm -rf .heroku_cache/public/assets`
  puts "Precompiling assets..."
  `cd .heroku_cache && rake assets:clean RAILS_ENV=production`
  `cd .heroku_cache && rake assets:precompile RAILS_ENV=production`
  
  system 'cd .heroku_cache && export JAVASCRIPT=`ls public/assets | grep application | grep js | grep -v gz`; perl -pi -e "s/javascript_include_tag \"application\"/javascript_include_tag \"http:\/\/static.scoopinion.com\/assets\/${JAVASCRIPT}\"/g" app/views/layouts/*.html.erb'
  
  system 'cd .heroku_cache && export CSS=`ls public/assets | grep application | grep css | grep -v gz`; perl -pi -e "s/stylesheet_link_tag \"application\"/stylesheet_link_tag \"http:\/\/static.scoopinion.com\/assets\/${CSS}\"/g" app/views/layouts/*.html.erb'
  
  puts `cd .heroku_cache && git add . && git commit -m 'deploy'`
  `cd .heroku_cache && git push -f heroku master`

end

task :heroku_staging do

  puts "Deploying to scoopinion-staging.heroku.com..."

  unless File.directory?(".heroku_cache_staging")
    
    puts "Creating cache..."
    
    `mkdir .heroku_cache_staging`
    `cd .heroku_cache_staging && hg clone ssh://hg@bitbucket.org/villesundberg/scoopinion .`
    `cd .heroku_cache_staging && git init && git remote add heroku git@heroku.com:scoopinion-staging.git`
  end
  
  puts `cd .heroku_cache_staging && hg incoming | grep summary`
  `cd .heroku_cache_staging && hg pull && hg up`
  `cd .heroku_cache_staging && git add . && git commit -m 'deploy'`
  `cd .heroku_cache_staging && git push -f heroku master`

end


task :heroku_deploy_demos do

  unless File.directory?(".heroku_cache_demos")
    `mkdir .heroku_cache_demos`
    `cd .heroku_cache_demos && hg clone ssh://hg@bitbucket.org/villesundberg/scoopinion .`
    `cd .heroku_cache_demos && git init && git remote add heroku git@heroku.com:demosscoopinion.git`
  end

  puts `cd .heroku_cache && hg incoming | grep summary`
  `cd .heroku_cache_demos && hg pull && hg up`
  `cd .heroku_cache_demos && git add . && git commit -m 'deploy'`
  `cd .heroku_cache_demos && git push -f heroku master`

end
