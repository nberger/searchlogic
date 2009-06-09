require File.expand_path(File.dirname(__FILE__) + "/spec_helper")

describe "SearchProxy" do
  context "initialization" do
    it "should require a class" do
      lambda { Searchlogic::SearchProxy.new }.should raise_error(ArgumentError)
    end
  
    it "should set the conditions" do
      search = User.search(:username => "bjohnson")
      search.conditions.should == {:username => "bjohnson"}
    end
  end
  
  context "setting conditions" do
    it "should set the conditions and be accessible individually" do
      search = User.search(:username => "bjohnson")
      search.username.should == "bjohnson"
    end
    
    it "should set the conditions and allow string keys" do
      search = User.search("username" => "bjohnson")
      search.username.should == "bjohnson"
    end
    
    it "should allow setting columns individually" do
      search = User.search
      search.username = "bjohnson"
      search.username.should == "bjohnson"
    end
    
    it "should allow setting custom conditions individually" do
      search = User.search
      search.username_gt = "bjohnson"
      search.username_gt.should == "bjohnson"
    end
    
    it "should not merge conflicting conditions into one value" do
      # This class should JUST be a proxy. It should not do anything more than that.
      # A user would be allowed to call both named scopes if they wanted.
      search = User.search
      search.username_greater_than = "bjohnson1"
      search.username_gt = "bjohnson2"
      search.username_greater_than.should == "bjohnson1"
      search.username_gt.should == "bjohnson2"
    end
    
    it "should allow setting custom conditions individually" do
      User.named_scope(:four_year_olds, :conditions => {:age => 4})
      search = User.search
      search.four_year_olds = true
      search.four_year_olds.should == true
    end
    
    it "should not allow setting conditions that are not scopes" do
      search = User.search
      lambda { search.unknown = true }.should raise_error(Searchlogic::SearchProxy::UnknownConditionError)
    end
  end
  
  context "taking action" do
    it "should return all when not given any conditions" do
      3.times { User.create }
      User.search.all.length.should == 3
    end
    
    it "should implement the current scope based on an association" do
      User.create
      company = Company.create
      user = company.users.create
      company.users.search.all.should == [user]
    end
    
    it "should implement the current scope based on a named scope" do
      User.named_scope(:four_year_olds, :conditions => {:age => 4})
      (3..5).each { |age| User.create(:age => age) }
      User.four_year_olds.search.all.should == User.find_all_by_age(4)
    end
    
    it "should call named scopes for conditions" do
      User.search(:age_less_than => 5).proxy_options.should == User.age_less_than(5).proxy_options
    end
    
    it "should alias exact column names to use equals" do
      User.search(:username => "joe").proxy_options.should == User.username_equals("joe").proxy_options
    end
    
    it "should recognize existing named scopes" do
      User.named_scope(:four_year_olds, { :conditions => { :age => 4 } })
      User.search(:four_year_olds => true).proxy_options.should == User.four_year_olds.proxy_options
    end
    
    it "should recognize conditions with a value of true where the named scope has an arity of 0" do
      User.search(:username_nil => true).proxy_options.should == User.username_nil.proxy_options
    end
    
    it "should recognize conditions with a value of 'true' where the named scope has an arity of 0" do
      User.search(:username_nil => "true").proxy_options.should == User.username_nil.proxy_options
    end
  
      it "should recognize conditions with a value of '1' where the named scope has an arity of 0" do
      User.search(:username_nil => "1").proxy_options.should == User.username_nil.proxy_options
    end
  
    it "should ignore conditions with a value of false where the named scope has an arity of 0" do
      User.search(:username_nil => false).proxy_options.should == {}
    end
  
    it "should ignore conditions with a value of 'false' where the named scope has an arity of 0" do
      User.search(:username_nil => false).proxy_options.should == {}
    end
    
    it "should recognize the order conditio" do
      User.search(:order => "ascend_by_username").proxy_options.should == User.ascend_by_username.proxy_options
    end
  end
end