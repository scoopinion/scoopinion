# -*- coding: utf-8 -*-
require 'spec_helper'

describe VisitsController do
  
  render_views
  
  context "#create" do
    
    context "when unauthenticated" do
      
      it "should fail" do
        put :create
        response.should_not be_success
      end
      
    end

    context "when authenticated" do

      before(:each) do
        activate_authlogic
        @user = User.create(:login => "villesundberg", :password => "test", :email => "v@example.com")
        @token = @user.single_access_token
        @site = Site.create(:url => "hs.fi", :name => "HS")
        @site.state = "confirmed"
        @site.save
      end
      
      context "with valid data" do
        
        
        before(:each) do
          @article_count = Article.count
          @visit_count = Visit.count
          post :create, :user_credentials => @token, :visit => { :score => 0 }, "article"=>{"url"=>"http://www.hs.fi/article", "title"=>"Apple’s iPhone 5 Makeover Won’t Carry Over To The Next-Gen iPod Touch | TechCrunch", "description"=>"In the past few months, have you felt like something's missing? Apple's new Fall release strategy has made it seem like someone just knocked Christmas right off the calendar, and so of course we're all thinking: \"You've made me wait, Apple — this better blow my mind.\" \n\nWell, have hope for the iPhone 5 because apparently the next-gen iPod touch isn't much to get excited about. According to sources from MacRumors as well as separately leaked info from a Concord Securities analyst, many of the hardware changes we'll be seeing on the long-anticipated iPhone 5 won't be showing up on the next iPod touch. ", "image_url"=>"http://tctechcrunch2011.files.wordpress.com/2011/09/screen-shot-2011-09-21-at-9-25-25-am.png?w=150"}, :format => "json"
          @json = JSON.parse(response.body)
        end
        
        it "should create an article" do
          Article.count.should == @article_count + 1
        end
        
        it "should create a visit" do
          Visit.count.should == @visit_count + 1
        end
        
        it "should succeed" do
          response.should be_success
        end
        
        it "should have the visit id in the response" do
          @json["visit"]["id"].should_not be_nil
        end
        
        it "should have the visit id in the response" do
          @json["article"]["id"].should_not be_nil
        end
        
        it "should contain the article comments" do
          @json["article"].has_key?("comments").should be_true
        end
        
        it "should contain the article score" do
          @json["article"].has_key?("score").should be_true
        end

        [ "link_click", "right_click", "mouse_move", "link_hover", "arrow_up", "arrow_down", "scroll_down", "scroll_up" ].each do |param|
          it "should contain #{param}" do
            @json["visit"].has_key?(param).should be_true
          end
        end

      end
      
      context "when updating" do

        before do
          Article.all{ |a| a.destroy }
          Visit.all{ |v| v.destroy }
          @article = Article.create(:url => "http://www.hs.fi/article2", :title => "Title2", :site => @site)
          @visit = Visit.create(:article => @article, :user => @user, :score => 2)
          
          put :create, :user_credentials => @token, "extension_version"=>"0.35", :visit => { :score => "4", "referrer"=>"http://techcrunch.com/2011/09/20/instagram-version-2/", "total_time"=>"39", "mouse_move"=>"152", "scroll_down"=>"20", "link_click"=>"1", "right_click"=>"0", "link_hover"=>"8", "arrow_up"=>"0", "arrow_down"=>"0", "scroll_up"=>"6"}, "article"=>{"url"=>"http://www.hs.fi/article2", "title"=>"Apple’s iPhone 5 Makeover Won’t Carry Over To The Next-Gen iPod Touch | TechCrunch", "description"=>"In the past few months, have you felt like something's missing? Apple's new Fall release strategy has made it seem like someone just knocked Christmas right off the calendar, and so of course we're all thinking: \"You've made me wait, Apple — this better blow my mind.\" \n\nWell, have hope for the iPhone 5 because apparently the next-gen iPod touch isn't much to get excited about. According to sources from MacRumors as well as separately leaked info from a Concord Securities analyst, many of the hardware changes we'll be seeing on the long-anticipated iPhone 5 won't be showing up on the next iPod touch. ", "image_url"=>"http://tctechcrunch2011.files.wordpress.com/2011/09/screen-shot-2011-09-21-at-9-25-25-am.png?w=150"}
          @visit.reload
          @article.reload
        end
        
        after do
          Article.all{ |a| a.destroy }
        end
        
        it "should not create another visit" do
          @article.visits.count.should == 1
        end
        
        it "should update the visit attributes" do
          @visit.total_time.should == 39
        end
        
      end

      
      context "with invalid data" do
        
        before do
          @article_count = Article.count
          put :create, :user_credentials => @token, :visit => { :title => "Test" }
        end      
        
        it "should fail" do
          response.should_not be_success
        end
        
        it "should not create an article" do
          Article.count.should == @article_count
        end

      end
      
    end
    
  end
end
