require_relative '../../spec_helper'

RSpec.describe Annotate::Helpers do
  describe '.skip_on_migration?' do
    subject { described_class.skip_on_migration? }

    before do
      allow(ENV).to receive(:[]).and_return(nil)
    end

    it { is_expected.to be_falsy }

    context "when ENV['ANNOTATE_SKIP_ON_DB_MIGRATE'] is set" do
      let(:key) { 'ANNOTATE_SKIP_ON_DB_MIGRATE' }
      let(:env_value) { '1' }

      before do
        allow(ENV).to receive(:[]).with(key).and_return(env_value)
      end

      it { is_expected.to be_truthy }
    end

    context "when ENV['skip_on_db_migrate'] is set" do
      let(:key) { 'skip_on_db_migrate' }
      let(:env_value) { '1' }

      before do
        allow(ENV).to receive(:[]).with(key).and_return(env_value)
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '.include_routes?' do
    subject { described_class.include_routes? }

    before do
      allow(ENV).to receive(:[]).and_return(nil)
    end

    it { is_expected.to be_falsy }

    context "when ENV['routes'] is set" do
      let(:key) { 'routes' }
      let(:env_value) { '1' }

      before do
        allow(ENV).to receive(:[]).with(key).and_return(env_value)
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '.include_models?' do
    subject { described_class.include_models? }

    before do
      allow(ENV).to receive(:[]).and_return(nil)
    end

    it { is_expected.to be_falsy }

    context "when ENV['models'] is set" do
      let(:key) { 'models' }
      let(:env_value) { '1' }

      before do
        allow(ENV).to receive(:[]).with(key).and_return(env_value)
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '.true?' do
    subject { described_class.true?(val) }

    let(:val) { nil }
    it { is_expected.to be_falsy }

    context 'when val is blank' do
      let(:val) { '' }

      it { is_expected.to be_falsy }
    end

    context 'when it matches the regex' do
      valid_truthy_values = %w[true t yes y 1]

      valid_truthy_values.each do |truthy_value|
        let(:val) { truthy_value }

        it "returns truthy for '#{truthy_value}'" do
          is_expected.to be_truthy
        end
      end
    end
  end
end
