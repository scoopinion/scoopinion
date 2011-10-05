desc "updates mailchimp list"
namespace :mailchimp do
  task :update => :environment do
    gb = Gibbon::API.new(Rails.application.config.mailchimp_api_key)
    puts gb.list_batch_subscribe(:id => "10ebb12040", :batch => User.all.map{|u| { "EMAIL" => u.email, "FNAME" => u.display_name.split(" ")[0], "LNAME" => u.display_name.split(" ").size == 1 ? "" : u.display_name.split(" ")[-1] } }, :update_existing => true, :double_optin => false)
  end
end
