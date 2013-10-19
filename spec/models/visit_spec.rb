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
  
  context "#referrer=" do
    before { @visit.referrer = "http://example.com" }
    
    its(:referrer) { should == "http://example.com" }
    
    context "when trying to set the referrer to an empty string" do
      before { @visit.referrer = "" }
      its(:referrer) { should == "http://example.com" }
    end
  
    context "when trying to set the referrer to nil" do
      before { @visit.referrer = nil }
      its(:referrer) { should == "http://example.com" }
    end
  
    context "when trying to set the referrer to another url" do
      before { @visit.referrer = "http://foxample.com" }
      its(:referrer) { should == "http://example.com" }
    end
end
  
  context "when otherwise valid" do
    
    before do
      @visit.article_id = 999
      @visit.user_id = 999
    end
    
    context "#total_time=" do
      
      it "should accept nil" do
        @visit.total_time = nil
      end
      
      it "should accept zero" do
        @visit.total_time = 0
      end
      
      it "should truncate large values" do
        @visit.total_time = 10000
        @visit.total_time.should == 1800
      end
      
      it "should accept string values" do
        @visit.total_time = "1800"
        @visit.total_time.should == 1800
      end

      it "should truncate large values with update_attribute" do
        @visit.update_attributes(:total_time => 10000)
        @visit.total_time.should == 1800
      end

      after { @visit.should be_valid }
      
    end
    
    context "referred_by_scoopinion" do
      
      it "should be true when coming from scoopinion" do
        @visit.referrer = "http://www.scoopinion.com/articles/99999"
        @visit.save
        @visit.referred_by_scoopinion.should == true
      end
      
      it "should be true when coming from huome.net" do
        @visit.referrer = "http://www.huome.net/articles/99999"
        @visit.save
        @visit.referred_by_scoopinion.should == true
      end

      it "should be false when coming from elsewhere" do
        @visit.referrer = "http://www.hs.fi"
        @visit.save
        @visit.referred_by_scoopinion.should == false
      end

    end
        
  end
    
end
