require 'spec_helper'

describe VisitsController do
  
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
        @user = User.create(:login => "villesundberg", :password => "test", :password_confirmation => "test", :email => "v@example.com")
        @token = @user.single_access_token
        @site = Site.create(:url => "hs.fi", :title => "HS")
        @site.state = "confirmed"
        @site.save
      end
      
      context "with valid data" do
        
        before(:each) do
          @article_count = Article.count
          @visit_count = Visit.count
          put :create, :user_credentials => @token, :visit => { :url => "http://www.hs.fi/article", :title => "Title"}
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
        
      end
      
      context "when updating" do
        
        before do
          Article.all{ |a| a.destroy }
          Visit.all{ |v| v.destroy }
          @article = Article.create(:url => "http://www.hs.fi/article2", :title => "Title2", :site => @site)
          @visit = Visit.create(:article => @article, :user => @user, :score => 2)
          
          put :create, :user_credentials => @token, :visit => { :url => "http://www.hs.fi/article2", :title => "Title2", :score => "4"}
          @visit.reload
          @article.reload
        end
        
        after do
          Article.all{ |a| a.destroy }
        end
        
        it "should not create another visit" do
          @article.visits.count.should == 1
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
