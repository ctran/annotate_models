#encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'annotate/annotate_models'
require 'annotate/active_record_patch'

describe AnnotateModels do
  def mock_class(table_name, primary_key, columns)
    options = {
      :connection   => mock("Conn", :indexes => []),
      :table_name   => table_name,
      :primary_key  => primary_key,
      :column_names => columns.map { |col| col.name.to_s },
      :columns      => columns
    }

    mock("An ActiveRecord class", options)
  end

  def mock_column(name, type, options={})
    default_options = {
      :limit   => nil,
      :null    => false,
      :default => nil
    }

    stubs = default_options.dup
    stubs.merge!(options)
    stubs.merge!(:name => name, :type => type)

    mock("Column", stubs)
  end

  it { AnnotateModels.quote(nil).should eql("NULL") }
  it { AnnotateModels.quote(true).should eql("TRUE") }
  it { AnnotateModels.quote(false).should eql("FALSE") }
  it { AnnotateModels.quote(25).should eql("25") }
  it { AnnotateModels.quote(25.6).should eql("25.6") }
  it { AnnotateModels.quote(1e-20).should eql("1.0e-20") }

  it "should get schema info" do
    klass = mock_class(:users, :id, [
                                     mock_column(:id, :integer),
                                     mock_column(:name, :string, :limit => 50)
                                    ])

    AnnotateModels.get_schema_info(klass, "Schema Info").should eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id   :integer          not null, primary key
#  name :string(50)       not null
#
EOS
  end

  it "should get schema info even if the primary key is not set" do
    klass = mock_class(:users, nil, [
                                     mock_column(:id, :integer),
                                     mock_column(:name, :string, :limit => 50)
                                    ])

    AnnotateModels.get_schema_info(klass, "Schema Info").should eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id   :integer          not null
#  name :string(50)       not null
#
EOS
  end

  it "should get schema info even if the primary key is array, if using composite_primary_keys" do
    klass = mock_class(:users, nil, [
                                     mock_column(:a_id, :integer),
                                     mock_column(:b_id, :integer),
                                     mock_column(:name, :string, :limit => 50)
                                    ])

    AnnotateModels.get_schema_info(klass, "Schema Info").should eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  a_id :integer          not null
#  b_id :integer          not null
#  name :string(50)       not null
#
EOS
  end
  it "should get schema info with enum type " do
    klass = mock_class(:users, nil, [
                                     mock_column(:id, :integer),
                                     mock_column(:name, :enum, :limit => [:enum1, :enum2])
                                    ])

    AnnotateModels.get_schema_info(klass, "Schema Info").should eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id   :integer          not null
#  name :enum             not null, (enum1, enum2)
#

EOS
  end

  it "should get schema info as RDoc" do
    klass = mock_class(:users, :id, [
                                     mock_column(:id, :integer),
                                     mock_column(:name, :string, :limit => 50)
                                    ])
    AnnotateModels.get_schema_info(klass, AnnotateModels::PREFIX, :format_rdoc => true).should eql(<<-EOS)
# #{AnnotateModels::PREFIX}
#
# Table name: users
#
# *id*::   <tt>integer, not null, primary key</tt>
# *name*:: <tt>string(50), not null</tt>
#--
# #{AnnotateModels::END_MARK}
#++
EOS
  end

  describe "#get_model_class" do
    require "tmpdir"

    module ::ActiveRecord
      class Base
        def self.has_many name
        end
      end
    end

    # todo: use 'files' gem instead
    def create(file, body="hi")
      file_path = File.join(AnnotateModels.model_dir, file)
      FileUtils.mkdir_p(File.dirname(file_path))

      File.open(file_path, "wb") do |f|
        f.puts(body)
      end
      file_path
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

    it "should not care about unknown macros" do
      create 'foo_with_macro.rb', <<-EOS
        class FooWithMacro < ActiveRecord::Base
          acts_as_awesome :yah
        end
      EOS
      check_class_name 'foo_with_macro.rb', 'FooWithMacro'
    end

    it "should not care about known macros" do
      create('foo_with_known_macro.rb', <<-EOS)
        class FooWithKnownMacro < ActiveRecord::Base
          has_many :yah
        end
      EOS
      check_class_name 'foo_with_known_macro.rb', 'FooWithKnownMacro'
    end

    it "should work with class names with ALL CAPS segments" do
      create('foo_with_capitals.rb', <<-EOS)
        class FooWithCAPITALS < ActiveRecord::Base
          acts_as_awesome :yah
          end
        EOS
      check_class_name 'foo_with_capitals.rb', 'FooWithCAPITALS'
    end

    it "should not complain of invalid multibyte char (USASCII)" do
      create 'foo_with_utf8.rb', <<-EOS
        #encoding: utf-8
        class FooWithUtf8 < ActiveRecord::Base
          UTF8STRINGS = %w[résumé façon âge]
        end
      EOS
      check_class_name 'foo_with_utf8.rb', 'FooWithUtf8'
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

    it "should allow known macros" do
      create('foo_with_known_macro.rb', <<-EOS)
        class FooWithKnownMacro < ActiveRecord::Base
          has_many :yah
        end
      EOS
      capturing(:stderr) do
        check_class_name 'foo_with_known_macro.rb', 'FooWithKnownMacro'
      end.should == ""
    end
  end

  describe "#remove_annotation_of_file" do
    require "tmpdir"

    def create(file, body="hi")
      path = File.join(@dir, file)
      File.open(path, "w") do |f|
        f.puts(body)
      end
      return path
    end

    def content(path)
      File.read(path)
    end

    before :each do
      @dir = Dir.mktmpdir 'annotate_models'
    end

    it "should remove before annotate" do
      path = create "before.rb", <<-EOS
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

      AnnotateModels.remove_annotation_of_file(path)

      content(path).should == <<-EOS
class Foo < ActiveRecord::Base
end
      EOS
    end

    it "should remove after annotate" do
      path = create "after.rb", <<-EOS
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

      AnnotateModels.remove_annotation_of_file(path)

      content(path).should == <<-EOS
class Foo < ActiveRecord::Base
end
      EOS
    end
  end

  describe "annotating a file" do
    before do
      @model_dir = Dir.mktmpdir('annotate_models')
      (@model_file_name, @file_content) = write_model "user.rb", <<-EOS
class User < ActiveRecord::Base
end
      EOS

      @klass = mock_class(:users, :id, [
                                        mock_column(:id, :integer),
                                        mock_column(:name, :string, :limit => 50)
                                       ])
      @schema_info = AnnotateModels.get_schema_info(@klass, "== Schema Info")
    end

    def write_model file_name, file_content
      fname = File.join(@model_dir, file_name)
      FileUtils.mkdir_p(File.dirname(fname))
      File.open(fname, "wb") { |f| f.write file_content }
      return fname, file_content
    end

    def annotate_one_file options = {}
      Annotate.set_defaults(options)
      options = Annotate.setup_options(options)
      AnnotateModels.annotate_one_file(@model_file_name, @schema_info, :position_in_class, options)

      # Wipe settings so the next call will pick up new values...
      Annotate.instance_variable_set('@has_set_defaults', false)
      Annotate::POSITION_OPTIONS.each { |key| ENV[key.to_s] = '' }
      Annotate::FLAG_OPTIONS.each { |key| ENV[key.to_s] = '' }
      Annotate::PATH_OPTIONS.each { |key| ENV[key.to_s] = '' }
    end

    it "should annotate the file before the model if position == 'before'" do
      annotate_one_file :position => "before"
      File.read(@model_file_name).should == "#{@schema_info}\n#{@file_content}"
    end

    it "should annotate before if given :position => :before" do
      annotate_one_file :position => :before
      File.read(@model_file_name).should == "#{@schema_info}\n#{@file_content}"
    end

    it "should annotate after if given :position => :after" do
      annotate_one_file :position => :after
      File.read(@model_file_name).should == "#{@file_content}\n#{@schema_info}"
    end

    it "should update annotate position" do
      annotate_one_file :position => :before

      another_schema_info = AnnotateModels.get_schema_info(mock_class(:users, :id, [mock_column(:id, :integer),]),
                                                           "== Schema Info")

      @schema_info = another_schema_info
      annotate_one_file :position => :after

      File.read(@model_file_name).should == "#{@file_content}\n#{another_schema_info}"
    end

    it "works with namespaced models (i.e. models inside modules/subdirectories)" do
      (model_file_name, file_content) = write_model "foo/user.rb", <<-EOS
class Foo::User < ActiveRecord::Base
end
      EOS

      klass = mock_class(:'foo_users', :id, [
                                        mock_column(:id, :integer),
                                        mock_column(:name, :string, :limit => 50)
                                       ])
      schema_info = AnnotateModels.get_schema_info(klass, "== Schema Info")
      AnnotateModels.annotate_one_file(model_file_name, schema_info, :position => :before)
      File.read(model_file_name).should == "#{schema_info}\n#{file_content}"
    end

    describe "if a file can't be annotated" do
       before do
         write_model('user.rb', <<-EOS)
           class User < ActiveRecord::Base
             raise "oops"
           end
         EOS
       end

       it "displays an error message" do
         capturing(:stdout) {
           AnnotateModels.do_annotations :model_dir => @model_dir, :is_rake => true
         }.should include("Unable to annotate user.rb: oops")
       end

       it "displays the full stack trace with --trace" do
         capturing(:stdout) {
           AnnotateModels.do_annotations :model_dir => @model_dir, :trace => true, :is_rake => true
         }.should include("/spec/annotate/annotate_models_spec.rb:")
       end

       it "omits the full stack trace without --trace" do
         capturing(:stdout) {
           AnnotateModels.do_annotations :model_dir => @model_dir, :trace => false, :is_rake => true
         }.should_not include("/spec/annotate/annotate_models_spec.rb:")
       end
    end

    describe "if a file can't be deannotated" do
       before do
         write_model('user.rb', <<-EOS)
           class User < ActiveRecord::Base
             raise "oops"
           end
         EOS
       end

       it "displays an error message" do
         capturing(:stdout) {
           AnnotateModels.remove_annotations :model_dir => @model_dir, :is_rake => true
         }.should include("Unable to deannotate user.rb: oops")
       end

       it "displays the full stack trace" do
         capturing(:stdout) {
           AnnotateModels.remove_annotations :model_dir => @model_dir, :trace => true, :is_rake => true
         }.should include("/user.rb:2:in `<class:User>'")
       end

       it "omits the full stack trace without --trace" do
         capturing(:stdout) {
           AnnotateModels.remove_annotations :model_dir => @model_dir, :trace => false, :is_rake => true
         }.should_not include("/user.rb:2:in `<class:User>'")
       end
    end
  end

  describe '.annotate_model_file' do
    before do
      class Foo < ActiveRecord::Base; end;
      AnnotateModels.stub(:get_model_class).with('foo.rb') { Foo }
      Foo.stub(:table_exists?) { false }
    end

    after { Object.send :remove_const, 'Foo' }

    it 'skips attempt to annotate if no table exists for model' do
      annotate_model_file = AnnotateModels.annotate_model_file([], 'foo.rb', nil, nil)

      annotate_model_file.should eq nil
    end
  end
end
