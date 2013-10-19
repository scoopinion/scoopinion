require 'spec_helper'

describe Article do
  
  before { @article = Article.new }
  
  subject { @article }
  
  context "when empty" do
    it { should_not be_valid }
  end
  
  context "with normal data" do
    
    before do 
      @article.title = "Foo"
      @article.url = "http://example.com/article"
    end
    
    it { should be_valid }
    
    context "" do
      
      after(:each) { @article.should_not be_valid}
      
      it "should not allow no article part in url" do
        @article.url = "http://example.com"
      end
      
      it "should not allow only slash in url" do
        @article.url = "http://example.com/"
      end
      
    end
    
    context "" do
      
      after(:each) { @article.should be_valid}
      
      it "should allow only numbers" do
        @article.url = "ex.com/123"
      end
      
      it "should allow multiple path parts" do
        @article.url = "ex.com/a/b/c"
      end
      
    end
      
  end
  
  
  describe "#url=" do
    
    context "without special query params" do
      
      after(:each) { @article.url.should == "hs.fi/article" }
      
      it "should strip http://" do
        @article.url = "http://hs.fi/article"
      end
      
      it "should strip https://" do
        @article.url = "https://hs.fi/article"
      end

      it "should strip #" do
        @article.url = "hs.fi/article#"
      end
      
      it "should strip query string" do
        @article.url = "hs.fi/article?foo=bar"
      end
      
      it "should strip trailing slash" do
        @article.url = "hs.fi/article/"
      end
      
      it "should strip extra slashes" do
        @article.url = "hs.fi///////////////////article/"
      end
      
    end
    
    context "with meaningful query string params" do
      
      it "should preserve a meaningful param" do
        @article.url = "hs.fi/article?id=999"
      end
      
      it "should not preserve a non-meaningful param" do
        @article.url = "hs.fi/article?id=999&session_id=123"
      end
      
      after(:each) do
        @article.url.should == "hs.fi/article?id=999"        
      end
      
    end
    
  end
    
  describe "#title=" do
          
    it "should not allow re-assignment of title after scraping" do      
      @article.title = "Correct title"
      @article.update_attributes :title => "Wrong"
      @article.title.should == "Correct title"
    end
        
  end
  
  describe "summary" do
    
    it "should work with a short body" do
      @summary_test = [ "Foo.", "<p>Foo.</p>" ]
    end
    
    after(:each) do
      @article.body = @summary_test[0]
      @article.create_summary.should == @summary_test[1]
    end
    
  end
  
  describe "image_url=" do
    
    it "should add http:// to a relative url" do
      @article.image_url = "foo"
      @article.image_url.should == "http://foo"
    end
    
    it "should leave an absolute url intact" do
      @article.image_url = "http://foo"
      @article.image_url.should == "http://foo"
    end
    
  end
  
  describe "calculate_average_visiting_time!" do
    
    before do
      @article = FactoryGirl.create(:article, :created_at => 1.week.ago)
    end
          
    it "should return the creation time when there are no visits" do
      @article.calculate_average_visiting_time!
      @article.average_visiting_time.should == @article.created_at
    end
    
    it "should return the only visit when there is one" do
      @visit = FactoryGirl.create :visit, :article => @article, :created_at => 3.days.ago
      @article.visits.reload
      @article.calculate_average_visiting_time!
      @article.average_visiting_time.should == @visit.created_at
    end
    
    it "should return the average when there are more than one visits" do
      @visits = [ 1.day.ago, 3.days.ago, 5.days.ago ].map{ |time| FactoryGirl.create :visit, :article => @article, :created_at => time }
      @article.visits.reload
      @article.calculate_average_visiting_time!
      @article.average_visiting_time.should be_within(1).of(@visits[1].created_at)
    end
    
    it "should disregard referred visits" do
      @visits = [ 3.days.ago, 5.days.ago ].map{ |time| FactoryGirl.create :visit, :article => @article, :created_at => time }
      @visits << FactoryGirl.create(:visit, :article => @article, :created_at => 1.day.ago, :referrer => "https://www.scoopinion.com")
      @article.visits.reload
      @article.calculate_average_visiting_time!
      @article.average_visiting_time.should be_within(1).of(@visits[0].created_at - 1.day)
    end
    
    it "should include indirect visits" do
      @visits = [ 3.days.ago, 5.days.ago ].map{ |time| FactoryGirl.create :visit, :article => @article, :created_at => time }
      @referrer = FactoryGirl.create(:article)
      FactoryGirl.create(:article_referral, :article => @article, :referrer => @referrer)
      FactoryGirl.create(:visit, :article => @referrer, :created_at => 1.day.ago)
      @article.visits.reload
      @article.indirect_visits.reload
      @article.calculate_average_visiting_time!
      @article.average_visiting_time.should be_within(1).of(@visits[0].created_at)
    end
    
  end
  
end
