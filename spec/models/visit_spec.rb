require 'spec_helper'

describe Visit do
  
  before { @visit = Visit.new }
  subject { @visit }
  
  context "with a previous visit in place" do
    
    before do
      Visit.create(:article_id => 999, :user_id => 999, :score => 1)
      @visit.article_id = 999
      @visit.user_id = 999
    end
    
    it { should_not be_valid }
    
  end
  
  context "#score=" do
    
    before {  @visit.score = 50 }
    
    it "should work initially" do
      @visit.score.should == 50
    end
    
  end
  
end
