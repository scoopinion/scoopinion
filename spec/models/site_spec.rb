require 'spec_helper'

describe Site do

  before { @site = Site.new }
  
  subject { @site }

  context "when empty" do
    it { should_not be_valid }
  end

  context "when name not empty" do
    before { @site.name = "Example" }
    it { should_not be_valid }
  end
  
  context "when everything present" do
    
    before(:each) do 
      @site.name = "Example"
      @site.url = "example.com"
    end
    
    context "url=" do
      
      before(:each) do
        @params = { :name => "Example" }
      end
      
      after(:each) do
        site = Site.create(@params)
        site.normalize_url
        site.url.should == "example.com"
        site.destroy
      end
      
      it "fixes the url when the url ends in a slash" do
        @params[:url] = "example.com/"
      end

      it "fixes the url when the url starts with http://" do
        @params[:url] = "http://example.com"
      end
      
      it "fixes the url when the url starts with http://www." do
        @params[:url] = "http://www.example.com"
      end
      
      it "fixes the url when the url starts with http://www. and ends in a slash" do
        @params[:url] = "http://www.example.com/"
      end

      it "fixes the url when the url starts with a dot" do
        @params[:url] = ".example.com"
      end
      
      it "fixes the url when the url ends with a dot" do
        @params[:url] = "example.com."
      end
      
    end
        
  end
  
  context "with valid data" do
    
    before do 
      @site.name = "Example"
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
      @site.name = "Example"
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
    
    it "should not find a blacklisted section" do
      @site.sections.create(:url => "discussion.example.com", :blacklisted => true)
      Site.find_by_full_url("discussion.example.com/threads/foo").should == nil
    end
    
  end
end
