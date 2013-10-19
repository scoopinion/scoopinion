  require 'spec_helper'

describe User do

  context "#create_anonymous" do
    subject { @user }
    it "should create an anonymous user" do
      User.create_anonymous.should be_valid
    end
  end

  context "#apply_omniauth" do
    before :each do
      Delayed::Worker.delay_jobs = false
      @user = FactoryGirl.create(:anonymous_user)
      @friends = []
      @user.stub_chain(:facebook, :friends).and_return(@friends)
    end

    context "when provider is facebook" do

      before { @omniauth_hash = {"provider"=>"facebook", "uid"=>  "1234567", "info"=>{"nickname"=>"jbloggs", "email"=>"user@example.com", "name"=>"Joe Bloggs", "first_name"=>"Joe", "last_name"=>"Bloggs", "image"=>"http://graph.facebook.com/1234567/picture?type=square", "urls"=>{:Facebook=>"http://www.facebook.com/jbloggs"}, "location"=>"Palo Alto, California"}, "credentials"=>{"token"=>"ABCDEF...", "expires_at"=>1321747205, "expires"=>true}, "extra"=>{"raw_info"=>{"id"=>"1234567", "name"=>"Joe Bloggs", "first_name"=>"Joe", "last_name"=>"Bloggs", "link"=>"http://www.facebook.com/jbloggs", "username"=>"jbloggs", "location"=>{"id"=>"123456789", "name"=>"Palo Alto, California"}, "gender"=>"male", "email"=>"joe@bloggs.com", "timezone"=>-8, "locale"=>"en_US", "verified"=>true, "updated_time"=>"2011-11-11T06:21:03+0000"}}}}

      context "saving fields" do

        before :each do
          @user.apply_omniauth(@omniauth_hash)
          @user.save!
        end

        it "should apply omniauth fields for user" do
          @user.email.should == "user@example.com"
          @user.login.should == "user@example.com"
          @user.username.should == "Joe Bloggs"
          @user.gender.should == "male"
          @user.locale.should == "en_US"
          @user.location.should == "Palo Alto, California"
          # TODO: Add birthday and hometown
        end

      end

      context "saving friends" do       

        before :each do
          5.times do 
            friend = FbGraph::TestUser.new(FactoryGirl.generate :uid)
            friend.name = FactoryGirl.generate(:name)
            @friends << friend
          end
          @user.stub_chain(:facebook, :friends).and_return(@friends)
          @user.apply_omniauth(@omniauth_hash)
          @user.save!
        end 

        it "should save users facebook friendships" do
          @user.should have(5).facebook_friendships
        end

        it "should create valid facebook friends" do
          @user.should have(5).facebook_friends
        end

      end

      context "when there is existing potential user" do
        before :each do
          uid = FactoryGirl.generate :uid
          @existing_friend = PotentialUser.create(:uid => uid, :name => FactoryGirl.generate(:name))

          @new_friend = FbGraph::TestUser.new(uid)
          @new_friend.name = FactoryGirl.generate(:name)
          @friends << @new_friend

          @user.stub_chain(:facebook, :friends).and_return(@friends)
          @user.apply_omniauth(@omniauth_hash)
          @user.save!
        end
        it "should update name" do
          @user.facebook_friends.first.name.should == @new_friend.name
        end
        it "should not save new object" do
          PotentialUser.count.should == 1
        end
        it "should assign existing user id" do
          @user.facebook_friends.first.id.should == @existing_friend.id
        end
      end

    end

    context "when provider is twitter" do
      before do
        @omniauth_hash = {"provider"=>"twitter", "uid"=>"221894195", "info"=>{"nickname"=>"MikaelKoponen", "name"=>"Mikael Koponen", "location"=>"", "image"=>"http://a0.twimg.com/profile_images/2638217238/f4753ede65997cc92ad4ac33aa7c8928_normal.png", "description"=>"Developer at Scoopinion. Studying Information Networks at Aalto University.", "urls"=>{"Website"=>nil, "Twitter"=>"http://twitter.com/MikaelKoponen"}}}
        @user.apply_omniauth(@omniauth_hash)
        @user.save!
      end
      it "saves user name" do
        @user.username.should == "Mikael Koponen"
      end 

    end


  end
  
  context "#feed_languages" do
    
    before do
      @user = FactoryGirl.create(:user)
      @user.locale.should == nil
    end
    
    it "should have a default language" do
      @user.feed_languages.should == [ "en" ]
    end
    
    context "when a language is graylisted" do
      
      before do
        @user.locale = "fi"
        @user.languages.create(language: "fi")
        @user.site_language.should == "fi"
        @user.languages_including_blacklisted.where(language: "en").first.greylisted.should be_true
      end
      
      
      it "should not be in feed" do
        @user.feed_languages.should == [ "fi" ]
      end
      
    end
    
    context "with a locale other than finnish or english" do
      
      before do
        @user.locale = "nl"
        @user.languages.create(language: "nl")
        @user.languages_including_blacklisted.where(language: "en").first.blacklisted.should be_false
      end
      
      it "should have english in feed anyway" do
        @user.feed_languages.should == [ "nl", "en" ]
      end
      
      context "with english blacklisted" do
        
        before do
          @user.languages_including_blacklisted.where(language: "en").first.update_column(:blacklisted, true)
        end
        
        it "should not have english in feed" do
          @user.feed_languages.should == [ "nl" ]
        end
        
      end
            
    end
    
  end
  
  context "#digest_list" do
    
    before do
      @signups = [ nil, 4.days.ago, 2.days.ago ].map do |signup_time|
        FactoryGirl.create(:user, :signup_completed_at => signup_time)
      end
      @unsubscribed = FactoryGirl.create(:user, :unsubscribed => true)
    end
    
    it "should contain a user whose signup time is unknown" do
      User.digest_list.should include(@signups[0])
    end
    
    it "should contain a user whose signup time is more than 3 days ago" do
      User.digest_list.should include(@signups[1])
    end
    
    it "should contain a user whose signup time is less than 3 days ago" do
      User.digest_list.should_not include(@signups[2])
    end
    
    it "should contain an unsubscribed user" do
      User.digest_list.should_not include(@unsubscribed)
    end

  end

  describe "#has_saved" do
    before do
      @user = FactoryGirl.create(:user)
      @article = FactoryGirl.create(:article)
    end
    it "returns true for saved articles" do
      @user.bookmarked_articles << @article
      @user.has_bookmarked?(@article).should be_true
    end
    it "returns false for unsaved articles" do
      @user.has_bookmarked?(@article).should be_false
    end
  end
  
end
