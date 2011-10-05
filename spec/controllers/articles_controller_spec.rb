require 'spec_helper'

describe ArticlesController do
  
  context "#index" do
    
    context "when not authenticated" do
      
      it "should succeed" do
        put :index
        response.should be_success
      end

    end
    
  end
  
end
