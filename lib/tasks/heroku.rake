desc "deploys to heroku"
task :heroku_deploy do

  puts "Deploying to scoopinion.com..."

  unless File.directory?(".heroku_cache")
    
    puts "Creating cache..."
    
    `mkdir .heroku_cache`
    `cd .heroku_cache && hg clone ssh://hg@bitbucket.org/villesundberg/scoopinion .`
    `cd .heroku_cache && git init && git remote add heroku git@heroku.com:scoopinion.git`
  end
  
  puts `cd .heroku_cache && hg incoming | grep summary`
  puts "Refreshing..."
  `rm -rf .heroku_cache/app/assets`
  puts "hg pull"
  `cd .heroku_cache && hg pull`
  puts "hg up"
  `cd .heroku_cache && hg up -C production`
  puts "hg revert ."
  `cd .heroku_cache && hg revert .`
  puts "Purging assets..."
  `rm -rf .heroku_cache/public/assets`
  `rm -rf .heroku_cache/spec .heroku_cache/test`
  
  puts "Precompiling assets..."
  `cd .heroku_cache && rake assets:clean RAILS_ENV=production`
  `cd .heroku_cache && rake assets:precompile RAILS_ENV=production`
  
  puts `cd .heroku_cache && git add .sass-cache`
  puts `cd .heroku_cache && git add --all . && git commit -m 'deploy'`
  `cd .heroku_cache && git push -f heroku master`

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
