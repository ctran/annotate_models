#encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'annotated_models'
require 'active_support/core_ext'
require 'active_support/inflector'
require 'fakefs/spec_helpers'
require 'tmpdir'

describe AnnotatedModels do
  include FakeFS::SpecHelpers

  def mock_class(table_name, primary_key, columns)
    options = {
      :connection   => mock("Conn", :indexes => []),
      :table_name   => table_name,
      :model_name   => mock("ModelName", :human => ""),
      :primary_key  => primary_key.to_s,
      :column_names => columns.map { |col| col.name.to_s },
      :columns      => columns
    }
    klass = mock("An ActiveRecord class", options)
    columns.reverse.each do | column |
      klass.stub!(:human_attribute_name).with(column.name, {:default=>""}).and_return("")
    end
    klass
  end

  def mock_column(name, type, options={})
    default_options = {
      :limit   => nil,
      :null    => false,
      :default => nil
    }

    stubs = default_options.dup
    stubs.merge!(options)
    stubs.merge!(:name => name, :type => type, :humanize => name.to_s.humanize)

    mock("Column", stubs)
  end

  it { AnnotatedModels.quote(nil).should eql("NULL") }
  it { AnnotatedModels.quote(true).should eql("TRUE") }
  it { AnnotatedModels.quote(false).should eql("FALSE") }
  it { AnnotatedModels.quote(25).should eql("25") }
  it { AnnotatedModels.quote(25.6).should eql("25.6") }
  it { AnnotatedModels.quote(1e-20).should eql("1.0e-20") }

  it "should get schema info" do
    klass = mock_class(:users, :id, [
                                     mock_column(:id, :integer),
                                     mock_column(:name, :string, :limit => 50)
                                    ])

    AnnotatedModels.get_schema_info(klass, "Schema Info").should eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id   :integer         not null, primary key
#  name :string(50)      not null
#

EOS
  end

  it "should get schema info as RDoc" do
    klass = mock_class(:users, :id, [
                                     mock_column(:id, :integer),
                                     mock_column(:name, :string, :limit => 50)
                                    ])
    ENV.stub!(:[]).with('format_rdoc').and_return(true)
    AnnotatedModels.get_schema_info(klass, AnnotatedModels::PREFIX).should eql(<<-EOS)
# #{AnnotatedModels::PREFIX}
#
# Table name: users
#
# *id*::   <tt>integer, not null, primary key</tt>
# *name*:: <tt>string(50), not null</tt>
#--
# #{AnnotatedModels::END_MARK}
#++

EOS
  end

  describe "#get_model_class" do

    def create(file, body="hi")
      path = @dir + '/' + file
      File.open(path, "w") do |f|
        f.puts(body)
      end
      path
    end

    before :all do
      @dir = File.join Dir.tmpdir, "annotate_models"
      FileUtils.mkdir_p(@dir)
      AnnotatedModels.model_dir = @dir

      create('foo.rb', <<-EOS)
        class Foo < ActiveRecord::Base
        end
      EOS
      create('foo_with_macro.rb', <<-EOS)
        class FooWithMacro < ActiveRecord::Base
          acts_as_awesome :yah
        end
      EOS
      create('foo_with_utf8.rb', <<-EOS)
        #encoding: utf-8
        class FooWithUtf8 < ActiveRecord::Base
          UTF8STRINGS = %w[résumé façon âge]
        end
      EOS
    end

    it "should work" do
      klass = AnnotatedModels.get_model_class("foo.rb")
      klass.name.should == "Foo"
    end

    it "should not care about unknown macros" do
      klass = AnnotatedModels.get_model_class("foo_with_macro.rb")
      klass.name.should == "FooWithMacro"
    end

    it "should not complain of invalid multibyte char (USASCII)" do
      klass = AnnotatedModels.get_model_class("foo_with_utf8.rb")
      klass.name.should == "FooWithUtf8"
    end
  end

  describe "#remove_annotation_of_file" do
    def create(file, body="hi")
      File.open(file, "w") do |f|
        f.puts(body)
      end
    end

    def content(file)
      File.read(file)
    end

    it "should remove before annotate" do
      create("before.rb", <<-EOS)
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

      AnnotatedModels.remove_annotation_of_file("before.rb")

      content("before.rb").should == <<-EOS
class Foo < ActiveRecord::Base
end
      EOS
    end

    it "should remove after annotate" do
      create("after.rb", <<-EOS)
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

      AnnotatedModels.remove_annotation_of_file("after.rb")

      content("after.rb").should == <<-EOS
class Foo < ActiveRecord::Base
end
      EOS
    end
  end

  describe "annotating a file" do
    before do
      @file_name    = "user.rb"
      @file_content = <<-EOS
class User < ActiveRecord::Base
end
      EOS
      File.open(@file_name, "wb") { |f| f.write @file_content }
      @klass = mock_class(:users, :id, [
                                        mock_column(:id, :integer),
                                        mock_column(:name, :string, :limit => 50)
                                       ])
      @schema_info = AnnotatedModels.get_schema_info(@klass, "== Schema Info")
    end

    it "should annotate the file before the model if position == 'before'" do
      AnnotatedModels.annotate_one_file(@file_name, @schema_info, :position => "before")
      File.read(@file_name).should == "#{@schema_info}#{@file_content}"
    end

    it "should annotate before if given :position => :before" do
      AnnotatedModels.annotate_one_file(@file_name, @schema_info, :position => :before)
      File.read(@file_name).should == "#{@schema_info}#{@file_content}"
    end

    it "should annotate before if given :position => :after" do
      AnnotatedModels.annotate_one_file(@file_name, @schema_info, :position => :after)
      File.read(@file_name).should == "#{@file_content}\n#{@schema_info}"
    end

    it "should update annotate position" do
      AnnotatedModels.annotate_one_file(@file_name, @schema_info, :position => :before)

      another_schema_info = AnnotatedModels.get_schema_info(mock_class(:users, :id, [mock_column(:id, :integer),]),
                                                           "== Schema Info")

      AnnotatedModels.annotate_one_file(@file_name, another_schema_info, :position => :after)

      File.read(@file_name).should == "#{@file_content}\n#{another_schema_info}"
    end
  end
end
