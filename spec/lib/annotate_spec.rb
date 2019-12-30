require_relative '../spec_helper'

describe Annotate do
  describe '.version' do
    it 'has version' do
      expect(Annotate.version).to be_instance_of(String)
    end
  end
end
