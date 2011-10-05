module LanguageGuesser

  def self.guess(request)
    remote_ip = request.remote_ip
    @geoip ||= GeoIP.new("#{Rails.root}/db/GeoIP.dat")    
    if remote_ip != "127.0.0.1" #todo: check for other local addresses or set default value
      country = @geoip.country(remote_ip)[3].downcase
    end
    accepted = accepted_languages(request)
    accepted << country if country
    return accepted
  end
  
  def self.accepted_languages(request)
    # no language accepted
    return [] if request.env["HTTP_ACCEPT_LANGUAGE"].nil?
    
    # parse Accept-Language
    accepted = request.env["HTTP_ACCEPT_LANGUAGE"].split(",")
    accepted = accepted.map { |l| l.strip.split(";") }
    accepted = accepted.map { |l|
      if (l.size == 2)
        # quality present
        [ l[0].split("-")[0].downcase, l[1].sub(/^q=/, "").to_f ]
      else
        # no quality specified =&gt; quality == 1
        [ l[0].split("-")[0].downcase, 1.0 ]
      end
    }
    
    accepted.map{ |a| a[0]}.uniq
  end
end
