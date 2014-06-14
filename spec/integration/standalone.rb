require 'common_validation'

module Annotate
  module Validations
    class Standalone < Base
      def self.schema_annotation
        return <<-RUBY
# == Schema Information
#
# Table name: tasks
#
#  id         :integer          not null, primary key
#  content    :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
RUBY
      end

      def self.test_commands
        return %q{
          bin/annotate --require ./config/init.rb
        }
      end

      def self.verify_output(output)
        expect(output).to match(/Annotated \(1\): Task/)
      end

      def self.verify_files(test_rig)
        return Annotate::Validations::Common.verify_files({
          :model => true,
          :test => false,
          :fixture => false,
          :factory => false,
          :routes => false
        }, test_rig, self.schema_annotation, nil, true)
      end
    end
  end
end
