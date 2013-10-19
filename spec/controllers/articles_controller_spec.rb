require 'spec_helper'

describe ArticlesController do
  
  context "#show" do
    
    before do
      mock_delay = double('mock_delay').as_null_object 
      UserMailer.any_instance.stub(:delay).and_return(mock_delay)
      @article = FactoryGirl.create :article
    end
        
    context "with firefox extension" do
      
      before do
        request.env["x-scoopinion-extension-version"] = "firefox-0.7"
        get :show, :id => @article.id
      end
      
      it "should succeed" do
        response.should be_success
      end
      
    end
    
    context "WITH extension" do
      
      before { request.cookies["scoopinion-extension-version"] = "chrome-0.32" }
      
      context "with an old user" do
        
        before do
          @user = FactoryGirl.create(:user, :created_at => Time.utc(2012,1,1))
          login_as @user
          get :show, :id => @article.id
        end
        
        it "should redirect" do
          response.should redirect_to @article.remote_url
        end
        
      end
      
      context "WITH a new user" do
        
        before do
          @user = FactoryGirl.create(:user, :created_at => Time.utc(2012,10,24))
          login_as @user
          get :show, :id => @article.id
        end
        
        it "should redirect" do
          response.should be_success
        end

      end
      
      context "via email" do
        
        before do
          request.cookies["scoopinion-extension-version"] = "chrome-0.32"
          get :show, :id => @article.id, :source => "email"
        end

        it "shouldn't redirect" do
          response.should be_success
        end

      end
      
    end
    
  end
  
end
