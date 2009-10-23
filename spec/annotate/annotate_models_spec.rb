require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'annotate/annotate_models'
require 'rubygems'
require 'activesupport'

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
