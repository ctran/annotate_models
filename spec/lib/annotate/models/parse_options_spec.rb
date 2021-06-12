require_relative '../../../spec_helper'
require 'annotate/annotate_models'
require 'annotate/active_record_patch'
require 'active_support/core_ext/string'
require 'files'
require 'tmpdir'

describe AnnotateModels do
  describe '.parse_options' do
    let(:options) do
      {
        root_dir: '/root',
        model_dir: 'app/models,app/one,  app/two   ,,app/three',
        skip_subdirectory_model_load: false
      }
    end

    before :each do
      AnnotateModels.send(:parse_options, options)
    end

    describe '@root_dir' do
      subject do
        AnnotateModels.instance_variable_get(:@root_dir)
      end

      it 'sets @root_dir' do
        is_expected.to eq('/root')
      end
    end

    describe '@model_dir' do
      subject do
        AnnotateModels.instance_variable_get(:@model_dir)
      end

      it 'separates option "model_dir" with commas and sets @model_dir as an array of string' do
        is_expected.to eq(['app/models', 'app/one', 'app/two', 'app/three'])
      end
    end

    describe '@skip_subdirectory_model_load' do
      subject do
        AnnotateModels.instance_variable_get(:@skip_subdirectory_model_load)
      end

      context 'option is set to true' do
        let(:options) do
          {
            root_dir: '/root',
            model_dir: 'app/models,app/one,  app/two   ,,app/three',
            skip_subdirectory_model_load: true
          }
        end

        it 'sets skip_subdirectory_model_load to true' do
          is_expected.to eq(true)
        end
      end

      context 'option is set to false' do
        let(:options) do
          {
            root_dir: '/root',
            model_dir: 'app/models,app/one,  app/two   ,,app/three',
            skip_subdirectory_model_load: false
          }
        end

        it 'sets skip_subdirectory_model_load to false' do
          is_expected.to eq(false)
        end
      end
    end
  end
end
