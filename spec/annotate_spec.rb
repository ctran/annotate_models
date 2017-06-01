require File.dirname(__FILE__) + '/spec_helper.rb'

describe Annotate do
  it 'should have a version' do
    expect(Annotate::VERSION).to be_instance_of(String)
  end
end
