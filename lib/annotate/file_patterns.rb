module FilePatterns
  class << self
    def test_files(root_directory)
      [
          File.join(root_directory, UNIT_TEST_DIR,  '%MODEL_NAME%_test.rb'),
          File.join(root_directory, MODEL_TEST_DIR,  '%MODEL_NAME%_test.rb'),
          File.join(root_directory, SPEC_MODEL_DIR, '%MODEL_NAME%_spec.rb'),
      ]
    end

    def fixture_files(root_directory)
      [
          File.join(root_directory, FIXTURE_TEST_DIR, '%TABLE_NAME%.yml'),
          File.join(root_directory, FIXTURE_SPEC_DIR, '%TABLE_NAME%.yml'),
          File.join(root_directory, FIXTURE_TEST_DIR, '%PLURALIZED_MODEL_NAME%.yml'),
          File.join(root_directory, FIXTURE_SPEC_DIR, '%PLURALIZED_MODEL_NAME%.yml'),
      ]
    end

    def scaffold_files(root_directory)
      [
          File.join(root_directory, CONTROLLER_TEST_DIR, '%PLURALIZED_MODEL_NAME%_controller_test.rb'),
          File.join(root_directory, CONTROLLER_SPEC_DIR, '%PLURALIZED_MODEL_NAME%_controller_spec.rb'),
          File.join(root_directory, REQUEST_SPEC_DIR,    '%PLURALIZED_MODEL_NAME%_spec.rb'),
          File.join(root_directory, ROUTING_SPEC_DIR,    '%PLURALIZED_MODEL_NAME%_routing_spec.rb'),
      ]
    end

    def factory_files(root_directory)
      [
          File.join(root_directory, EXEMPLARS_TEST_DIR,     '%MODEL_NAME%_exemplar.rb'),
          File.join(root_directory, EXEMPLARS_SPEC_DIR,     '%MODEL_NAME%_exemplar.rb'),
          File.join(root_directory, BLUEPRINTS_TEST_DIR,    '%MODEL_NAME%_blueprint.rb'),
          File.join(root_directory, BLUEPRINTS_SPEC_DIR,    '%MODEL_NAME%_blueprint.rb'),
          File.join(root_directory, FACTORY_GIRL_TEST_DIR,  '%MODEL_NAME%_factory.rb'),    # (old style)
          File.join(root_directory, FACTORY_GIRL_SPEC_DIR,  '%MODEL_NAME%_factory.rb'),    # (old style)
          File.join(root_directory, FACTORY_GIRL_TEST_DIR,  '%TABLE_NAME%.rb'),            # (new style)
          File.join(root_directory, FACTORY_GIRL_SPEC_DIR,  '%TABLE_NAME%.rb'),            # (new style)
          File.join(root_directory, FABRICATORS_TEST_DIR,   '%MODEL_NAME%_fabricator.rb'),
          File.join(root_directory, FABRICATORS_SPEC_DIR,   '%MODEL_NAME%_fabricator.rb'),
      ]
    end

    def serialize_files(root_directory)
      [
          File.join(root_directory, SERIALIZERS_DIR,       '%MODEL_NAME%_serializer.rb'),
          File.join(root_directory, SERIALIZERS_TEST_DIR,  '%MODEL_NAME%_serializer_spec.rb'),
          File.join(root_directory, SERIALIZERS_SPEC_DIR,  '%MODEL_NAME%_serializer_spec.rb')
      ]
    end

    def files_by_pattern(root_directory, pattern_type)
      case pattern_type
        when 'test'       then test_files(root_directory)
        when 'fixture'    then fixture_files(root_directory)
        when 'scaffold'   then scaffold_files(root_directory)
        when 'factory'    then factory_files(root_directory)
        when 'serializer' then serialize_files(root_directory)
        when 'controller'
          [File.join(root_directory, CONTROLLER_DIR, '%PLURALIZED_MODEL_NAME%_controller.rb')]
        when 'admin'
          [File.join(root_directory, ACTIVEADMIN_DIR, '%MODEL_NAME%.rb')]
        when 'helper'
          [File.join(root_directory, HELPER_DIR, '%PLURALIZED_MODEL_NAME%_helper.rb')]
        else
          []
      end
    end
  end
end
