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

  end

end
