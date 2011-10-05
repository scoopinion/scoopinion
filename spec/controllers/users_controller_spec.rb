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
  
end
