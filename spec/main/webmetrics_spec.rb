require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "spec setup" do
  it "should run the specs without error" do
    true.should be_true
  end
end

describe "Webmetrics()" do

  context "with an request.env" do
    before(:each) do
      @env = {}
      Webmetrics(@env)
    end

    it "should create a session" do
      Webmetrics.users.count.should eq(1)
    end

    it "should set the aarrr.session env variable" do
      user_attributes = Webmetrics.users.find_one
      @env["aarrr.session"].id.should eq(user_attributes["_id"])
    end
  end

end