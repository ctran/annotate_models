require_relative '../../../spec_helper'
require 'annotate/annotate_models'

describe AnnotateModels::FilePatterns do
  describe '.by_pattern' do
    subject { AnnotateModels::FilePatterns.generate(root_directory, pattern_type, options) }

    let(:root_directory) { '/root' }
    let(:options) { {} }

    context 'when pattern_type is "test"' do
      let(:pattern_type) { 'test' }

      it 'returns patterns of test files' do
        is_expected.to eq([
          '/root/test/unit/%MODEL_NAME%_test.rb',
          '/root/test/models/%MODEL_NAME%_test.rb',
          '/root/spec/models/%MODEL_NAME%_spec.rb'
        ])
      end
    end

    context 'when pattern_type is "fixture"' do
      let(:pattern_type) { 'fixture' }

      it 'returns patterns of fixture files' do
        is_expected.to eq([
          '/root/test/fixtures/%TABLE_NAME%.yml',
          '/root/spec/fixtures/%TABLE_NAME%.yml',
          '/root/test/fixtures/%PLURALIZED_MODEL_NAME%.yml',
          '/root/spec/fixtures/%PLURALIZED_MODEL_NAME%.yml'
        ])
      end
    end

    context 'when pattern_type is "scaffold"' do
      let(:pattern_type) { 'scaffold' }

      it 'returns patterns of scaffold files' do
        is_expected.to eq([
          '/root/test/controllers/%PLURALIZED_MODEL_NAME%_controller_test.rb',
          '/root/spec/controllers/%PLURALIZED_MODEL_NAME%_controller_spec.rb',
          '/root/spec/requests/%PLURALIZED_MODEL_NAME%_spec.rb',
          '/root/spec/routing/%PLURALIZED_MODEL_NAME%_routing_spec.rb'
        ])
      end
    end

    context 'when pattern_type is "factory"' do
      let(:pattern_type) { 'factory' }

      it 'returns patterns of factory files' do
        is_expected.to eq([
          '/root/test/exemplars/%MODEL_NAME%_exemplar.rb',
          '/root/spec/exemplars/%MODEL_NAME%_exemplar.rb',
          '/root/test/blueprints/%MODEL_NAME%_blueprint.rb',
          '/root/spec/blueprints/%MODEL_NAME%_blueprint.rb',
          '/root/test/factories/%MODEL_NAME%_factory.rb',
          '/root/spec/factories/%MODEL_NAME%_factory.rb',
          '/root/test/factories/%TABLE_NAME%.rb',
          '/root/spec/factories/%TABLE_NAME%.rb',
          '/root/test/factories/%PLURALIZED_MODEL_NAME%.rb',
          '/root/spec/factories/%PLURALIZED_MODEL_NAME%.rb',
          '/root/test/fabricators/%MODEL_NAME%_fabricator.rb',
          '/root/spec/fabricators/%MODEL_NAME%_fabricator.rb'
        ])
      end
    end

    context 'when pattern_type is "serializer"' do
      let(:pattern_type) { 'serializer' }

      it 'returns patterns of serializer files' do
        is_expected.to eq([
          '/root/app/serializers/%MODEL_NAME%_serializer.rb',
          '/root/test/serializers/%MODEL_NAME%_serializer_test.rb',
          '/root/spec/serializers/%MODEL_NAME%_serializer_spec.rb'
        ])
      end
    end

    context 'when pattern_type is "additional_file_patterns"' do
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

    context 'when pattern_type is "controller"' do
      let(:pattern_type) { 'controller' }

      it 'returns patterns of controller files' do
        is_expected.to eq([
          '/root/app/controllers/%PLURALIZED_MODEL_NAME%_controller.rb'
        ])
      end
    end

    context 'when pattern_type is "admin"' do
      let(:pattern_type) { 'admin' }

      it 'returns both singular and pluralized model names' do
        is_expected.to eq(['/root/app/admin/%MODEL_NAME%.rb', '/root/app/admin/%PLURALIZED_MODEL_NAME%.rb'])
      end
    end

    context 'when pattern_type is "helper"' do
      let(:pattern_type) { 'helper' }

      it 'returns patterns of helper files' do
        is_expected.to eq([
          '/root/app/helpers/%PLURALIZED_MODEL_NAME%_helper.rb'
        ])
      end
    end
  end
end
