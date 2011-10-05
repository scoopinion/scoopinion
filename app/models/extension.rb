class Extension
  
  def self.build(options={})
    output_dir = "#{Rails.root}/tmp/extensions/chrome-#{Time.now.nsec}"
    output_file = "#{Rails.root}/tmp/extensions/huomenet-#{Time.now.nsec}.crx"
        
    system "mkdir -p #{output_dir}"
    
    @server_url = perl_safe(options[:server_url])
    @update_url = perl_safe(options[:update_url])
    
    @replace_expression = "s/API_KEY/#{options[:key]}/; s/EXTENSION_NAME/#{options[:name]}/; s/SERVER_URL/#{@server_url}/; s/UPDATE_URL/#{@update_url}/; s/userID = \"USER_ID\"/userID = \"#{options[:user_id]}\"/"
    @filter_command = "perl -p -e '#{@replace_expression}' #{Rails.root}/extension/src/$F > #{output_dir}/$F"
    
    system "for F in `cd #{Rails.root}/extension/src && find . -type f`; do #{@filter_command}; done"
    
    system "bundle exec crxmake --pack-extension=#{output_dir} --extension-output=#{output_file} --pack-extension-key=#{Rails.root}/bundler/publicmind.pem"
    
    if File.exists? output_file
      return output_file
    else
      return false
    end
  end
  
  private
  
  def self.perl_safe(string)
    string.gsub(":", "\:").gsub("/", "\\/")
  end
  
end

