require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'annotate/annotate_models'
require 'rubygems'
require 'activesupport'

describe AnnotateModels do
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
    module ::ActiveRecord
      class Base
      end
    end

    def create(file, body="hi")
      File.open(@dir + '/' + file, "w") do |f|
        f.puts(body)
      end
    end

    before :all do
      require "tmpdir"
      @dir = Dir.tmpdir + "/#{Time.now.to_i}" + "/annotate_models"
      FileUtils.mkdir_p(@dir)
      AnnotateModels.model_dir = @dir
      create('foo.rb', <<-EOS)
        class Foo < ActiveRecord::Base
        end
      EOS
      create('foo_with_macro.rb', <<-EOS)
        class FooWithMacro < ActiveRecord::Base
          acts_as_awesome :yah
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
  end

end
