require 'spec_helper'

describe Site do

  before { @site = Site.new }

  subject { @site }

  context "when empty" do
    it { should_not be_valid }
  end

  context "when title not empty" do
    before { @site.title = "Example" }
    it { should_not be_valid }
  end
  
  context "when everything present" do
    
    before do 
      @site.title = "Example"
      @site.url = "example.com"
    end
    
    after(:each) do
      @site.should_not be_valid
    end
    
    it "is invalid when the url ends in a slash" do
      @site.url = "example.com/"
    end

    it "is invalid when the url starts with http://" do
      @site.url = "http://example.com"
    end
    
    it "is invalid when the url starts with a dot" do
      @site.url = ".example.com"
    end
    
    it "is invalid when the url ends with a dot" do
      @site.url = "example.com."
    end
    
    it "is invalid when there are no dots" do
      @site.url = "examplecom"
    end
    
  end
  
  context "with valid data" do
    
    before do 
      @site.title = "Example"
    end
    
    after(:each) do
      @site.should be_valid
    end
    
    it "is valid when there is a directory in the url" do
      @site.url = "example.com/news"
    end
    
    it "is valid when there is a dash in the url" do
      @site.url = "ex-ample.com"
    end
    
    it "is valid when there is a number in the url" do
      @site.url = "ex4mple.com"
    end
  end
  
  describe "#find_by_full_url(url)" do
    before do
      @site.title = "Example"
      @site.url = "example.com"
      @site.state = "confirmed"
      @site.save
    end
    
    it "should be found with its url" do
      Site.find_by_full_url("example.com").should == @site
    end
    
    it "should be found with anything after the slash" do
      Site.find_by_full_url("example.com/article").should == @site
    end
    
    it "should ignore leading http" do
      Site.find_by_full_url("http://example.com").should == @site
    end
    
    it "should ignore leading https" do
      Site.find_by_full_url("https://example.com").should == @site
    end

    it "should ignore the query string question mark" do
      Site.find_by_full_url("example.com?article").should == @site
    end
    
    it "should ignore the hash" do
      Site.find_by_full_url("example.com#article").should == @site
    end
    
    it "should allow a subdomain" do
      Site.find_by_full_url("subdomain.example.com").should == @site
    end
    
    it "should allow many subdomains" do
      Site.find_by_full_url("a.b.c.subdomain.example.com").should == @site
    end

  end
end
