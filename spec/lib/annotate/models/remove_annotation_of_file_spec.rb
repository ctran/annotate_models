require_relative '../../../spec_helper'
require_relative 'model_spec_helper'
require 'annotate/annotate_models'
require 'annotate/active_record_patch'
require 'active_support/core_ext/string'
require 'files'
require 'tmpdir'

describe AnnotateModels do
  describe '.remove_annotation_of_file' do
    subject do
      AnnotateModels.remove_annotation_of_file(path)
    end

    let :tmpdir do
      Dir.mktmpdir('annotate_models')
    end

    let :path do
      File.join(tmpdir, filename).tap do |path|
        File.open(path, 'w') do |f|
          f.puts(file_content)
        end
      end
    end

    let :file_content_after_removal do
      subject
      File.read(path)
    end

    let :expected_result do
      <<~EOS
        class Foo < ActiveRecord::Base
        end
      EOS
    end

    context 'when annotation is before main content' do
      let :filename do
        'before.rb'
      end

      let :file_content do
        <<~EOS
          # == Schema Information
          #
          # Table name: foo
          #
          #  id                  :integer         not null, primary key
          #  created_at          :datetime
          #  updated_at          :datetime
          #

          class Foo < ActiveRecord::Base
          end
        EOS
      end

      it 'removes annotation' do
        expect(file_content_after_removal).to eq expected_result
      end
    end

    context 'when annotation is before main content and CRLF is used for line breaks' do
      let :filename do
        'before.rb'
      end

      let :file_content do
        <<~EOS
          # == Schema Information
          #
          # Table name: foo\r\n#
          #  id                  :integer         not null, primary key
          #  created_at          :datetime
          #  updated_at          :datetime
          #
          \r\n
          class Foo < ActiveRecord::Base
          end
        EOS
      end

      it 'removes annotation' do
        expect(file_content_after_removal).to eq expected_result
      end
    end

    context 'when annotation is before main content and with opening wrapper' do
      let :filename do
        'opening_wrapper.rb'
      end

      let :file_content do
        <<~EOS
          # wrapper
          # == Schema Information
          #
          # Table name: foo
          #
          #  id                  :integer         not null, primary key
          #  created_at          :datetime
          #  updated_at          :datetime
          #

          class Foo < ActiveRecord::Base
          end
        EOS
      end

      subject do
        AnnotateModels.remove_annotation_of_file(path, wrapper_open: 'wrapper')
      end

      it 'removes annotation' do
        expect(file_content_after_removal).to eq expected_result
      end
    end

    context 'when annotation is before main content and with opening wrapper' do
      let :filename do
        'opening_wrapper.rb'
      end

      let :file_content do
        <<~EOS
          # wrapper\r\n# == Schema Information
          #
          # Table name: foo
          #
          #  id                  :integer         not null, primary key
          #  created_at          :datetime
          #  updated_at          :datetime
          #

          class Foo < ActiveRecord::Base
          end
        EOS
      end

      subject do
        AnnotateModels.remove_annotation_of_file(path, wrapper_open: 'wrapper')
      end

      it 'removes annotation' do
        expect(file_content_after_removal).to eq expected_result
      end
    end

    context 'when annotation is after main content' do
      let :filename do
        'after.rb'
      end

      let :file_content do
        <<~EOS
          class Foo < ActiveRecord::Base
          end

          # == Schema Information
          #
          # Table name: foo
          #
          #  id                  :integer         not null, primary key
          #  created_at          :datetime
          #  updated_at          :datetime
          #

        EOS
      end

      it 'removes annotation' do
        expect(file_content_after_removal).to eq expected_result
      end
    end

    context 'when annotation is after main content and with closing wrapper' do
      let :filename do
        'closing_wrapper.rb'
      end

      let :file_content do
        <<~EOS
          class Foo < ActiveRecord::Base
          end

          # == Schema Information
          #
          # Table name: foo
          #
          #  id                  :integer         not null, primary key
          #  created_at          :datetime
          #  updated_at          :datetime
          #
          # wrapper

        EOS
      end

      subject do
        AnnotateModels.remove_annotation_of_file(path, wrapper_close: 'wrapper')
      end

      it 'removes annotation' do
        expect(file_content_after_removal).to eq expected_result
      end
    end

    context 'when annotation is before main content and with comment "-*- SkipSchemaAnnotations"' do
      let :filename do
        'skip.rb'
      end

      let :file_content do
        <<~EOS
          # -*- SkipSchemaAnnotations
          # == Schema Information
          #
          # Table name: foo
          #
          #  id                  :integer         not null, primary key
          #  created_at          :datetime
          #  updated_at          :datetime
          #

          class Foo < ActiveRecord::Base
          end
        EOS
      end

      let :expected_result do
        file_content
      end

      it 'does not remove annotation' do
        expect(file_content_after_removal).to eq expected_result
      end
    end
  end
end
