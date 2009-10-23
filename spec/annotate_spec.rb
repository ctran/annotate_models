require File.dirname(__FILE__) + '/spec_helper.rb'

describe Annotate do

  it "should have a version" do
    Annotate.version.should be_instance_of(String)
  end

end
