module Annotate
  module Validations
    module Common
      def self.test_commands
        return %q{
          bin/annotate &&
          bin/annotate --routes
        }
      end

      def self.verify_output(output)
        output.should =~ /Annotated \(1\): Task/
        output.should =~ /Route file annotated./
      end

      def self.verify_files(which_files, test_rig, schema_annotation, routes_annotation, place_before=true)
        check_task_model(test_rig, schema_annotation, place_before) if(which_files[:model])
        check_task_unittest(test_rig, schema_annotation, place_before) if(which_files[:test])
        check_task_fixture(test_rig, schema_annotation, place_before) if(which_files[:fixture])
        check_task_factory(test_rig, schema_annotation, place_before) if(which_files[:factory])
        check_routes(test_rig, routes_annotation, place_before) if(which_files[:routes])
      end

      def self.check_task_model(test_rig, annotation, place_before=true)
        model = apply_annotation(test_rig, "app/models/task.rb", annotation, place_before)
        File.read("app/models/task.rb").should == model
      end

      def self.check_routes(test_rig, annotation, place_before=true)
        routes = apply_annotation(test_rig, "config/routes.rb", annotation, place_before)
        File.read("config/routes.rb").
          sub(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}/, 'YYYY-MM-DD HH:MM').
          should == routes
      end

      def self.check_task_unittest(test_rig, annotation, place_before=true)
        unittest = apply_annotation(test_rig, "test/unit/task_test.rb", annotation, place_before)
        File.read("test/unit/task_test.rb").should == unittest
      end

      def self.check_task_modeltest(test_rig, annotation, place_before=true)
        unittest = apply_annotation(test_rig, "test/models/task_test.rb", annotation, place_before)
        File.read("test/models/task_test.rb").should == unittest
      end

      def self.check_task_factory(test_rig, annotation, place_before=true)
        fixture = apply_annotation(test_rig, "test/factories/tasks.rb", annotation, place_before)
        File.read("test/factories/tasks.rb").should == fixture
      end

      def self.check_task_fixture(test_rig, annotation, place_before=true)
        fixture = apply_annotation(test_rig, "test/fixtures/tasks.yml", annotation, place_before)
        File.read("test/fixtures/tasks.yml").should == fixture
      end

    protected

      def self.apply_annotation(test_rig, fname, annotation, place_before=true)
        corpus = File.read(File.join(test_rig, fname))
        if place_before
          annotation + "\n" + corpus
        else
          corpus + "\n" + annotation
        end
      end
    end
  end
end

module Annotate
  module Validations
    class Base
      def self.test_commands
        return Annotate::Validations::Common.test_commands
      end

      def self.verify_output(output)
        return Annotate::Validations::Common.verify_output(output)
      end

      def self.verify_files(test_rig)
        return Annotate::Validations::Common.verify_files({
          :model => true,
          :test => true,
          :fixture => true,
          :factory => false,
          :routes => true
        }, test_rig, self.schema_annotation, self.route_annotation, true)
      end

      def self.foo
        require 'pry'
        require 'pry-coolline'
        binding.pry
      end
    end
  end
end
