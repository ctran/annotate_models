require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'annotate/annotate_models'

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

end
