require_relative '../../../spec_helper'
require 'annotate/annotate_models'

describe AnnotateModels::FilePatterns do
  describe '.by_pattern' do
    subject { AnnotateModels::FilePatterns.generate(root_directory, pattern_type, options) }

    context 'when pattern_type is "additional_file_patterns"' do
      let(:root_directory) { nil }
      let(:pattern_type) { 'additional_file_patterns' }

      context 'when additional_file_patterns is specified in the options' do
        let(:additional_file_patterns) do
          [
            '%PLURALIZED_MODEL_NAME%/**/*.rb',
            '%PLURALIZED_MODEL_NAME%/*_form'
          ]
        end

        let(:options) { { additional_file_patterns: additional_file_patterns } }

        it 'returns additional_file_patterns in the argument "options"' do
          is_expected.to eq(additional_file_patterns)
        end
      end

      context 'when additional_file_patterns is not specified in the options' do
        let(:options) { {} }

        it 'returns an empty array' do
          is_expected.to eq([])
        end
      end
    end
  end
end
