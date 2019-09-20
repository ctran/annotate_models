require_relative '../spec_helper'

describe Annotate do
  it 'should have a version' do
    expect(Annotate.version).to be_instance_of(String)
  end

  describe 'TRUE_RE' do
    it do
      expect(Annotate::TRUE_RE).to be_a(Regexp)
    end
  end

  describe '.skip_on_migration?' do
    it "checks ENV for 'ANNOTATE_SKIP_ON_DB_MIGRATE' or 'skip_on_db_migrate'" do
      expect(ENV).to receive(:[]).twice
      described_class.skip_on_migration?
    end
  end

  describe '.include_routes?' do
    it "checks ENV with 'routes'" do
      expect(ENV).to receive(:[]).with('routes')
      described_class.include_routes?
    end
  end

  describe '.include_models?' do
    it "checks ENV with 'models'" do
      expect(ENV).to receive(:[]).with('models')
      described_class.include_models?
    end
  end
end
