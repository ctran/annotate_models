require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'annotate/annotate_models'
require 'annotate/active_record_patch'
require 'rubygems'
require 'active_support'

describe AnnotateModels do

  def mock_klass(stubs={})
    @mock_file ||= mock("Klass", stubs)
  end

  def mock_column(stubs={})
    @mock_column ||= mock("Column", stubs)
  end

  it { AnnotateModels.quote(nil).should eql("NULL") }
  it { AnnotateModels.quote(true).should eql("TRUE") }
  it { AnnotateModels.quote(false).should eql("FALSE") }
  it { AnnotateModels.quote(25).should eql("25") }
  it { AnnotateModels.quote(25.6).should eql("25.6") }
  it { AnnotateModels.quote(1e-20).should eql("1.0e-20") }

  it "should get schema info" do

    AnnotateModels.get_schema_info(mock_klass(
      :connection => mock("Conn", :indexes => []),
      :table_name => "users",
      :primary_key => "id",
      :column_names => ["id","login"],
      :columns => [
        mock_column(:type => "integer", :default => nil, :null => false, :name => "id", :limit => nil),
        mock_column(:type => "string", :default => nil, :null => false, :name => "name", :limit => 50)
      ]), "Schema Info").should eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id    :integer         not null, primary key
#  id    :integer         not null, primary key
#

EOS

  end

  describe "#get_model_class" do
    require "tmpdir"

    module ::ActiveRecord
      class Base
      end
    end

    def create(file, body="hi")
      file_path = File.join(AnnotateModels.model_dir, file)
      FileUtils.mkdir_p(File.dirname(file_path))

      File.open(file_path, "w") do |f|
        f.puts(body)
      end
    end

    def check_class_name(file, class_name)
      klass = AnnotateModels.get_model_class(file)

      klass.should_not == nil
      klass.name.should == class_name
    end

    before :each do
      AnnotateModels.model_dir = Dir.mktmpdir 'annotate_models'
    end

    it "should work" do
      create 'foo.rb', <<-EOS
        class Foo < ActiveRecord::Base
        end
      EOS
      check_class_name 'foo.rb', 'Foo'
    end

    it "should not care about unknown macros" do
      create 'foo_with_macro.rb', <<-EOS
        class FooWithMacro < ActiveRecord::Base
          acts_as_awesome :yah
        end
      EOS
      check_class_name 'foo_with_macro.rb', 'FooWithMacro'
    end

    it "should find models with non standard capitalization" do
      create 'foo_with_capitals.rb', <<-EOS
        class FooWithCAPITALS < ActiveRecord::Base
        end
      EOS
      check_class_name 'foo_with_capitals.rb', 'FooWithCAPITALS'
    end

    it "should find models inside modules" do
      create 'bar/foo_inside_bar.rb', <<-EOS
        module Bar
          class FooInsideBar < ActiveRecord::Base
          end
        end
      EOS
      check_class_name 'bar/foo_inside_bar.rb', 'Bar::FooInsideBar'
    end

    it "should find models inside modules with non standard capitalization" do
      create 'bar/foo_inside_capitals_bar.rb', <<-EOS
        module BAR
          class FooInsideCapitalsBAR < ActiveRecord::Base
          end
        end
      EOS
      check_class_name 'bar/foo_inside_capitals_bar.rb', 'BAR::FooInsideCapitalsBAR'
    end

    it "should find non-namespaced models inside subdirectories" do
      create 'bar/non_namespaced_foo_inside_bar.rb', <<-EOS
        class NonNamespacedFooInsideBar < ActiveRecord::Base
        end
      EOS
      check_class_name 'bar/non_namespaced_foo_inside_bar.rb', 'NonNamespacedFooInsideBar'
    end

    it "should find non-namespaced models with non standard capitalization inside subdirectories" do
      create 'bar/non_namespaced_foo_with_capitals_inside_bar.rb', <<-EOS
        class NonNamespacedFooWithCapitalsInsideBar < ActiveRecord::Base
        end
      EOS
      check_class_name 'bar/non_namespaced_foo_with_capitals_inside_bar.rb', 'NonNamespacedFooWithCapitalsInsideBar'
    end

    it "should not get confused by existing annotations on a model when the schema changes" do
      create 'foo.rb', <<-EOS
class Foo < ActiveRecord::Base
end
# == Schema Information
#
# Table name: users
#
#  id   :integer(4)      not null, primary key
#  name :string
#
# Indexes
#
#  index_users_on_name  (name) UNIQUE
#

EOS

      info_block = <<-EOS
# == Schema Information
#
# Table name: users
#
#  id   :integer(4)      not null, primary key
#  name :string
#  new  :string
#
# Indexes
#
#  index_users_on_name  (name) UNIQUE
#

EOS
      fname = File.join(AnnotateModels.model_dir, 'foo.rb')

      AnnotateModels.annotate_one_file(fname, info_block).should be_true

      File.read(fname).should == <<-EOS
class Foo < ActiveRecord::Base
end
# == Schema Information
#
# Table name: users
#
#  id   :integer(4)      not null, primary key
#  name :string
#  new  :string
#
# Indexes
#
#  index_users_on_name  (name) UNIQUE
#

EOS
    end
  end
end
