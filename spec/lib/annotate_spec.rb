require_relative '../spec_helper'

describe Annotate do
  it 'should have a version' do
    expect(Annotate.version).to be_instance_of(String)
  end
end
