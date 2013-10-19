desc "updates mailchimp list"

namespace :mailchimp do
  task :update => :environment do
    gb = Gibbon.new("9f4c42b9a64d61f7dc39bce194ec5852-us2")
    puts gb.list_batch_subscribe(:id => "4f66e7e57a", :batch => User.where{ email != ''}.where(:unsubscribed => false).map{|u| { "EMAIL" => u.email, "FNAME" => u.display_name.split(" ")[0], "LNAME" => u.display_name.split(" ").size == 1 ? "" : u.display_name.split(" ")[-1] } }, :update_existing => true, :double_optin => false)
  end
end
