xml.instruct!
xml.gupdate "xmlns" => 'http://www.google.com/update2/response', "protocol" => '2.0' do
  xml.app "appid" => @app_id do
    xml.updatecheck "codebase" => @extension_url, "version" => @version
  end
end

