module AnnotateModels
  # This module provides module method to get file paths.
  module FilePatterns
    # Controller files
    CONTROLLER_DIR       = File.join('app', 'controllers')

    # Active admin registry files
    ACTIVEADMIN_DIR      = File.join('app', 'admin')

    # Helper files
    HELPER_DIR           = File.join('app', 'helpers')

    # File.join for windows reverse bar compat?
    # I dont use windows, can`t test
    UNIT_TEST_DIR        = File.join('test', 'unit')
    MODEL_TEST_DIR       = File.join('test', 'models') # since rails 4.0
    SPEC_MODEL_DIR       = File.join('spec', 'models')

    FIXTURE_TEST_DIR     = File.join('test', 'fixtures')
    FIXTURE_SPEC_DIR     = File.join('spec', 'fixtures')

    # Other test files
    CONTROLLER_TEST_DIR  = File.join('test', 'controllers')
    CONTROLLER_SPEC_DIR  = File.join('spec', 'controllers')
    REQUEST_SPEC_DIR     = File.join('spec', 'requests')
    ROUTING_SPEC_DIR     = File.join('spec', 'routing')

    # Object Daddy http://github.com/flogic/object_daddy/tree/master
    EXEMPLARS_TEST_DIR   = File.join('test', 'exemplars')
    EXEMPLARS_SPEC_DIR   = File.join('spec', 'exemplars')

    # Machinist http://github.com/notahat/machinist
    BLUEPRINTS_TEST_DIR  = File.join('test', 'blueprints')
    BLUEPRINTS_SPEC_DIR  = File.join('spec', 'blueprints')

    # Factory Bot https://github.com/thoughtbot/factory_bot
    FACTORY_BOT_TEST_DIR = File.join('test', 'factories')
    FACTORY_BOT_SPEC_DIR = File.join('spec', 'factories')

    # Fabrication https://github.com/paulelliott/fabrication.git
    FABRICATORS_TEST_DIR = File.join('test', 'fabricators')
    FABRICATORS_SPEC_DIR = File.join('spec', 'fabricators')

    # Serializers https://github.com/rails-api/active_model_serializers
    SERIALIZERS_DIR      = File.join('app',  'serializers')
    SERIALIZERS_TEST_DIR = File.join('test', 'serializers')
    SERIALIZERS_SPEC_DIR = File.join('spec', 'serializers')

    class << self
      def generate(root_directory, pattern_type, options)
        case pattern_type
        when 'test'       then test_files(root_directory)
        when 'fixture'    then fixture_files(root_directory)
        when 'scaffold'   then scaffold_files(root_directory)
        when 'factory'    then factory_files(root_directory)
        when 'serializer' then serialize_files(root_directory)
        when 'additional_file_patterns'
          [options[:additional_file_patterns] || []].flatten
        when 'controller'
          [File.join(root_directory, CONTROLLER_DIR, '%PLURALIZED_MODEL_NAME%_controller.rb')]
        when 'admin'
          [
            File.join(root_directory, ACTIVEADMIN_DIR, '%MODEL_NAME%.rb'),
            File.join(root_directory, ACTIVEADMIN_DIR, '%PLURALIZED_MODEL_NAME%.rb')
          ]
        when 'helper'
          [File.join(root_directory, HELPER_DIR, '%PLURALIZED_MODEL_NAME%_helper.rb')]
        else
          []
        end
      end

      private

      def test_files(root_directory)
        [
          File.join(root_directory, UNIT_TEST_DIR,  '%MODEL_NAME%_test.rb'),
          File.join(root_directory, MODEL_TEST_DIR, '%MODEL_NAME%_test.rb'),
          File.join(root_directory, SPEC_MODEL_DIR, '%MODEL_NAME%_spec.rb')
        ]
      end

      def fixture_files(root_directory)
        [
          File.join(root_directory, FIXTURE_TEST_DIR, '%TABLE_NAME%.yml'),
          File.join(root_directory, FIXTURE_SPEC_DIR, '%TABLE_NAME%.yml'),
          File.join(root_directory, FIXTURE_TEST_DIR, '%PLURALIZED_MODEL_NAME%.yml'),
          File.join(root_directory, FIXTURE_SPEC_DIR, '%PLURALIZED_MODEL_NAME%.yml')
        ]
      end

      def scaffold_files(root_directory)
        [
          File.join(root_directory, CONTROLLER_TEST_DIR, '%PLURALIZED_MODEL_NAME%_controller_test.rb'),
          File.join(root_directory, CONTROLLER_SPEC_DIR, '%PLURALIZED_MODEL_NAME%_controller_spec.rb'),
          File.join(root_directory, REQUEST_SPEC_DIR,    '%PLURALIZED_MODEL_NAME%_spec.rb'),
          File.join(root_directory, ROUTING_SPEC_DIR,    '%PLURALIZED_MODEL_NAME%_routing_spec.rb')
        ]
      end

      def factory_files(root_directory)
        [
          File.join(root_directory, EXEMPLARS_TEST_DIR,   '%MODEL_NAME%_exemplar.rb'),
          File.join(root_directory, EXEMPLARS_SPEC_DIR,   '%MODEL_NAME%_exemplar.rb'),
          File.join(root_directory, BLUEPRINTS_TEST_DIR,  '%MODEL_NAME%_blueprint.rb'),
          File.join(root_directory, BLUEPRINTS_SPEC_DIR,  '%MODEL_NAME%_blueprint.rb'),
          File.join(root_directory, FACTORY_BOT_TEST_DIR, '%MODEL_NAME%_factory.rb'),    # (old style)
          File.join(root_directory, FACTORY_BOT_SPEC_DIR, '%MODEL_NAME%_factory.rb'),    # (old style)
          File.join(root_directory, FACTORY_BOT_TEST_DIR, '%TABLE_NAME%.rb'),            # (new style)
          File.join(root_directory, FACTORY_BOT_SPEC_DIR, '%TABLE_NAME%.rb'),            # (new style)
          File.join(root_directory, FACTORY_BOT_TEST_DIR, '%PLURALIZED_MODEL_NAME%.rb'), # (new style)
          File.join(root_directory, FACTORY_BOT_SPEC_DIR, '%PLURALIZED_MODEL_NAME%.rb'), # (new style)
          File.join(root_directory, FABRICATORS_TEST_DIR, '%MODEL_NAME%_fabricator.rb'),
          File.join(root_directory, FABRICATORS_SPEC_DIR, '%MODEL_NAME%_fabricator.rb')
        ]
      end

      def serialize_files(root_directory)
        [
          File.join(root_directory, SERIALIZERS_DIR,      '%MODEL_NAME%_serializer.rb'),
          File.join(root_directory, SERIALIZERS_TEST_DIR, '%MODEL_NAME%_serializer_test.rb'),
          File.join(root_directory, SERIALIZERS_SPEC_DIR, '%MODEL_NAME%_serializer_spec.rb')
        ]
      end
    end
  end
end
