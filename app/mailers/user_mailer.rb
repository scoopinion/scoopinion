class UserMailer < ActionMailer::Base
  default from: "Scoopinion <contact@scoopinion.com>", to: Proc.new { to }
  
  helper :user_mailer
  helper :digest
  helper :application
  
  layout "new_digest_mailer", :only => :fingerprint_launch_with_layout
  
  def you_have_requested_invitation(user)
    self.recipient = user
    @message = message
    attach_vcard!
    
    mail(
         :subject => t("mailer.welcome.subject"),
         ).deliver
  end
  
  def invite(user)
    self.recipient = user
    
    lang = I18n.locale == "en" ? "english" : "finnish"
    
    subject = ab_test("invite_email_#{lang}", [ "new", "old" ], :conversion => "create_account")
    
    mail(
         :subject => t("mailer.invite.subject.#{subject}")
         ).deliver
  end
  
  def remind(user)
    self.recipient = user
    mail(
         :subject => t("mailer.remind.subject"),
         :content_type => "text/html"
         ).deliver
  end
  
  def password_request(request)
    self.recipient = request.user
    @password_request = request
    mail(
         :subject => t("mailer.password_request.subject"),
         :content_type => "text/html"
         ).deliver
  end
    
  def you_have_invites(user)
    self.recipient = user
    @email = Email.create(user: @user, message_type: "you_have_invites")
    
    lang = I18n.locale == "en" ? "english" : "finnish"
    
    subject_version = ab_test("you_have_invites_email_topic_#{lang}", [ "new", "old" ], :conversion => "open_you_have_invites")
    
    mail(
         :subject => t("mailer.you_have_invites.subject.#{subject_version}")
         ).deliver
  end
  
  def addon_nag(options)
    self.recipient = options[:user]
    
    if !@user || 
        ( !options[:force] && 
          ( Email.where(user_id: @user.id, message_type: "addon_nag").any? || 
            @user.extension_installed_at ) )
      return false 
    end
    
    I18n.locale = @user.site_language
    Abingo.identity = @user.init_abingo
    
    @email = Email.create(user: @user, message_type: "addon_nag")
    
    if t("mailer.addon_nag.subject").is_a? Hash
      version = ab_test("addon_nag_english_subject_version", [ "v1", "v2" ], :conversion => "open_addon_nag")
      subject = t("mailer.addon_nag.subject.#{version}")
    else
      subject = t("mailer.addon_nag.subject")
    end
    
    install_link_type = ab_test("addon_nag_install_link_type", [ "traditional", "direct" ], :conversion => "install_addon")
    
    @install_link = { 
      "traditional" => page_url("extension", :host => Rails.application.config.email_link_host, :user_credentials => @user.single_access_token),
      "direct" => extension_redirect_url(:host => Rails.application.config.email_link_host, :user_credentials => @user.single_access_token)
    }[install_link_type]
    
    mail(
         :subject => subject
         ).deliver
  end
  
  def welcome_all_done(options)
    self.recipient = options[:user]

    @email = @user.emails.create(message_type: "welcome_all_done")
    
    attach_vcard!
    
    mail(
         :to => @user.email,
         :subject => t("mailer.welcome_all_done.subject")
         ).deliver
  end
  
  def welcome_no_addon(options)
    
    self.recipient = options[:user]
    
    if !@user ||
        ( !options[:force] && 
          ( Email.where(user_id: @user.id, message_type: "welcome_no_addon").any? || 
            Email.where(user_id: @user.id, message_type: "welcome_all_done").any? || 
            @user.extension_installed_at ) )
      return false
    end
    
    @email = @user.emails.create(message_type: "welcome_no_addon")
    attach_vcard!
    
    mail(
         :subject => t("mailer.welcome_no_addon.subject")
         ).deliver
  end
  
  def addon_installed(options)
    
    self.recipient = options[:user]
        
    if !@user ||
        ( !options[:force] && 
          ( Email.where(user_id: @user.id, message_type: "welcome_all_done").any? || 
            ! @user.extension_installed_at ) )
      return false
    end
    
    @email = @user.emails.create(message_type: "addon_installed")
    
    mail(
         :subject => t("mailer.addon_installed.subject")
         ).deliver
  end
  
  def activation_ping(options)
    
    self.recipient = options[:user]
    
    ab_test("activation_ping_#{I18n.locale}", [true, true], :conversion => "create_visit")

    @email = @user.emails.create(message_type: "activation_ping")
    
    mail(:subject => t("mailer.activation_ping.subject")).deliver
  end
  
  def launch(options)
    self.recipient = options[:user]
    I18n.locale = "en"
    @email = @user.emails.create(message_type: "chrome_web_store_migration")
    mail(:subject => t("mailer.launch.subject")).deliver
  end
  
  def your_data_is_ready(options)
    self.recipient = options[:user]
    @download_url = options[:download_url]
    @email = @user.emails.create(message_type: "your_data_is_ready")
    mail(:subject => t("mailer.your_data_is_ready.subject")).deliver
  end
  
  def fingerprint_launch(options)
    self.recipient = options[:user]
    @email = @user.emails.create(message_type: "fingerprint_launch")
    mail(:subject => t("mailer.fingerprint_launch.subject")).deliver
  end
  
  def fingerprint_launch_with_layout(options)
    self.recipient = options[:user]
    @email = @user.emails.create(message_type: "fingerprint_launch")
    mail(:subject => t("mailer.fingerprint_launch.subject")).deliver
  end
  
  def fingerprint_interesting(options)
    self.recipient = options[:user]
    @email = @user.emails.create(message_type: "fingerprint_interesting")
    mail(:subject => t("mailer.fingerprint_interesting.subject")).deliver
  end
  
  if defined?(MailView)

    class Preview < MailView
      
      def launch
        ::UserMailer.launch(:user => User.find(1))
      end
      
      def launch_fi
        ::UserMailer.launch(:user => User.find(1).tap{ |u| u.locale = "fi"})
      end

      def fingerprint_launch
        u = User.find(2)
        u.locale = "en"
        ::UserMailer.fingerprint_launch(:user => u)
      end
      
      def fingerprint_interesting
        u = User.find(2)
        u.locale = "en"
        ::UserMailer.fingerprint_interesting(:user => u)
      end

      def fingerprint_launch_with_layout
        ::UserMailer.fingerprint_launch_with_layout(:user => User.find(2))
      end
      
      
      def fingerprint_launch_with_layout_fi
        u = User.find(1)
        u.locale = "fi"
        ::UserMailer.fingerprint_launch_with_layout(:user => u)
      end

      def fingerprint_launch_fi
        u = User.find(1)
        u.locale = "fi"
        ::UserMailer.fingerprint_launch(:user => u)
      end

    end
    
  end
  
  private
  
  def attach_vcard!
    attachments["scoopinion.vcf"] = { 
      :mime_type => "text/x-vcard",
      :content => File.read("#{Rails.root}/public/scoopinion.vcf") 
    }    
  end
  
  def recipient=(user)
    @user = user
    I18n.locale = user.site_language
    Abingo.identity = user.init_abingo
    self.to = user.email
  end
  
  def to=(email)
    @to = email
  end
  
  def to
    @to
  end
  
  def params
    { }
  end
  
end
