#encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'annotate/annotate_models'
require 'active_support'
require 'fakefs/spec_helpers'

describe AnnotateModels do
  include FakeFS::SpecHelpers
  
  before(:all) do
    require "tmpdir"
    @dir = Dir.tmpdir + "/#{Time.now.to_i}" + "/annotate_models"
    FileUtils.mkdir_p(@dir)
    AnnotateModels.model_dir = @dir
  end
  
  module ::ActiveRecord
    class Base
    end
  end
  
  def create(file, body="hi")
    File.open(@dir + '/' + file, "w") do |f|
      f.puts(body)
    end
    @dir + '/' + file
  end
  
  def mock_class(table_name, primary_key, columns)
    options = {
      :connection   => mock("Conn", :indexes => []),
      :table_name   => table_name,
      :primary_key  => primary_key.to_s,
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
#  id   :integer         not null, primary key
#  name :string(50)      not null
#

EOS
  end
  
  describe "#get_model_class" do
    
    before :all do     
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
      klass = AnnotateModels.get_model_class("foo.rb")
      klass.name.should == "Foo"
    end
    
    it "should not care about unknown macros" do
      klass = AnnotateModels.get_model_class("foo_with_macro.rb")
      klass.name.should == "FooWithMacro"
    end
    
    it "should not complain of invalid multibyte char (USASCII)" do
      klass = AnnotateModels.get_model_class("foo_with_utf8.rb")
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

      AnnotateModels.remove_annotation_of_file("before.rb")

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

      AnnotateModels.remove_annotation_of_file("after.rb")

      content("after.rb").should == <<-EOS
class Foo < ActiveRecord::Base
end
      EOS
    end
  end

  describe "annotating a file" do
    before do
      @file_name = "user.rb"
      @file_content = "class User < ActiveRecord::Base; end"
      @klass = mock_class(:users, :id, [
                                        mock_column(:id, :integer),
                                        mock_column(:name, :string, :limit => 50)
                                       ])
    end

    def write_file
      File.open("user.rb", "w") do |f|
        f << @file_content
      end
    end

    it "should annotate the file before the model if position == 'before'" do
      write_file
      schema_info = AnnotateModels.get_schema_info(@klass, "Schema Info")

      AnnotateModels.annotate_one_file("user.rb", schema_info, :position => "before")

      File.read("user.rb").should == "#{schema_info}#{@file_content}\n"
    end

    it "should annotate before if given :position => :before" do
      write_file
      schema_info = AnnotateModels.get_schema_info(@klass, "Schema Info")

      AnnotateModels.annotate_one_file(@file_name, schema_info, :position => :before)

      File.read("user.rb").should == "#{schema_info}#{@file_content}\n"
    end
  end
end
