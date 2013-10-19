require 'spec_helper'

describe UsersController do
  
  context "#index" do
    
    context "when not logged in" do
      
      it "should succeed" do
        get :index
        response.should be_success
      end
    
    end
    
  end
    
  context "#create" do
    
    context "with anonymous user" do
      
      before(:each) do
        @user = FactoryGirl.create :anonymous_user
        login_as @user        
      end
      
      it "should succeed" do
        password = { :password => "test" }
        put :update, :id => @user.id, :user => FactoryGirl.build(:user).attributes.merge(password)
        response.should redirect_to "/introduction"
        assigns[:user].anonymous.should_not == true
      end
      
      context "with missing data" do
        
        before do
          put :update, :id => @user.id, :user => FactoryGirl.build(:user).attributes.except("crypted_password"), :format => "html"
        end
        
        it "should not redirect" do
          response.should be_success
        end
        
        it "should keep the user anonymous" do
          assigns[:user].anonymous.should == true          
        end
      
      end
      
    end
    
    context "without anonymous user" do
      
      it "should succeed" do
        password = { :password => "test" }
        post :create, :user => FactoryGirl.build(:user).attributes.merge(password)
        response.should redirect_to "/introduction"
        assigns[:user].anonymous.should_not == true
      end
      
    end
    
  end
  
  context "#update" do

    context "with an initial language" do
      
      before do
        @user = FactoryGirl.create :user
        @user.languages.create(:language => "nl")
        login_as @user
        put :update, id: @user.id, user: { languages: { 'nl' => 1, 'en' => 1 } }, format: 'json'
      end
      
      it "should succeed" do
        response.should be_success
      end

      it "should add a language" do
        assigns[:user].languages.count.should > 1
      end
      
    end
    
    context "with an extension version string" do
      
      before do
        @user = FactoryGirl.create :user
        @user.languages.create(:language => "nl")
        login_as @user
        put :update, id: @user.id, user: { extension: "chrome-1.0.0" }, format: 'json'
      end
      
      it "should succeed" do
        response.should be_success
      end
      
      it "should update extension_installed_at" do
        assigns[:user].extension_installed_at.should_not be_nil
      end
      
      it "should add an extension installation" do
        assigns[:user].extension_installations.count.should == 1
      end
            
    end
    
    context "with a legacy extension version string" do
    
      before do
        @user = FactoryGirl.create :user
        login_as @user
        put :update, id: @user.id, user: { extension: 1 }, format: 'json'
      end
      
      it "should update extension_installed_at" do
        assigns[:user].extension_installed_at.should_not be_nil
      end
      
    end
      
  end
  
  context "#show" do
    
    it "should show a normal user" do
      @user = FactoryGirl.create :user
      get :show, :id => @user.id
      response.should be_success
    end
    
    it "should not show a nonexisting user" do
      expect{ get :show, :id => -1 }.to raise_error(ActiveRecord::RecordNotFound)
    end
    
    it "should not show a potential user" do
      @user = FactoryGirl.create :potential_user
      expect{ get :show, :id => @user.id }.to raise_error(ActiveRecord::RecordNotFound)
    end

  end
  
end
