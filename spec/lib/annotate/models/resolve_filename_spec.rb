require_relative '../../../spec_helper'
require_relative 'model_spec_helper'
require 'annotate/annotate_models'
require 'annotate/active_record_patch'
require 'active_support/core_ext/string'
require 'files'
require 'tmpdir'

describe AnnotateModels do
  describe '.resolve_filename' do
    subject do
      AnnotateModels.resolve_filename(filename_template, model_name, table_name)
    end

    context 'When model_name is "example_model" and table_name is "example_models"' do
      let(:model_name) { 'example_model' }
      let(:table_name) { 'example_models' }

      context "when filename_template is 'test/unit/%MODEL_NAME%_test.rb'" do
        let(:filename_template) { 'test/unit/%MODEL_NAME%_test.rb' }

        it 'returns the test path for a model' do
          is_expected.to eq 'test/unit/example_model_test.rb'
        end
      end

      context "when filename_template is '/foo/bar/%MODEL_NAME%/testing.rb'" do
        let(:filename_template) { '/foo/bar/%MODEL_NAME%/testing.rb' }

        it 'returns the additional glob' do
          is_expected.to eq '/foo/bar/example_model/testing.rb'
        end
      end

      context "when filename_template is '/foo/bar/%PLURALIZED_MODEL_NAME%/testing.rb'" do
        let(:filename_template) { '/foo/bar/%PLURALIZED_MODEL_NAME%/testing.rb' }

        it 'returns the additional glob' do
          is_expected.to eq '/foo/bar/example_models/testing.rb'
        end
      end

      context "when filename_template is 'test/fixtures/%TABLE_NAME%.yml'" do
        let(:filename_template) { 'test/fixtures/%TABLE_NAME%.yml' }

        it 'returns the fixture path for a model' do
          is_expected.to eq 'test/fixtures/example_models.yml'
        end
      end
    end

    context 'When model_name is "parent/child" and table_name is "parent_children"' do
      let(:model_name) { 'parent/child' }
      let(:table_name) { 'parent_children' }

      context "when filename_template is 'test/fixtures/%PLURALIZED_MODEL_NAME%.yml'" do
        let(:filename_template) { 'test/fixtures/%PLURALIZED_MODEL_NAME%.yml' }

        it 'returns the fixture path for a nested model' do
          is_expected.to eq 'test/fixtures/parent/children.yml'
        end
      end
    end
  end
end
