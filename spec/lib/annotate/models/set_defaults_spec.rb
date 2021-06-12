require_relative '../../../spec_helper'
require 'annotate/annotate_models'
require 'annotate/active_record_patch'
require 'active_support/core_ext/string'
require 'files'
require 'tmpdir'

describe AnnotateModels do
  describe '.set_defaults' do
    subject do
      Annotate::Helpers.true?(ENV['show_complete_foreign_keys'])
    end

    context 'when default value of "show_complete_foreign_keys" is not set' do
      it 'returns false' do
        is_expected.to be(false)
      end
    end

    context 'when default value of "show_complete_foreign_keys" is set' do
      before do
        Annotate.set_defaults('show_complete_foreign_keys' => 'true')
      end

      it 'returns true' do
        is_expected.to be(true)
      end
    end

    after :each do
      ENV.delete('show_complete_foreign_keys')
    end
  end
end
