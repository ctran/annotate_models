require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'annotate/annotate_routes'

describe AnnotateRoutes do

  def mock_file(stubs={})
    @mock_file ||= mock(File, stubs)
  end

  it "should check if routes.rb exists" do
    File.should_receive(:join).with("config", "routes.rb").and_return(mock_file)
    File.should_receive(:exists?).with(@mock_file).and_return(false)
    AnnotateRoutes.should_receive(:puts).with("Can`t find routes.rb")

    AnnotateRoutes.do_annotate
  end

  it "should annotate!" do
    File.should_receive(:join).with("config", "routes.rb").and_return("config/routes.rb")
    File.should_receive(:exists?).with("config/routes.rb").and_return(true)
    AnnotateRoutes.should_receive(:`).with("rake routes").and_return("bad line\ngood line")
    File.should_receive(:read).with("config/routes.rb").and_return("bla")
    File.should_receive(:open).with("config/routes.rb", "wb").and_yield(mock_file)
    @mock_file.should_receive(:puts).with(/bla\n\n#== Route Info\n# Generated on .*\n#\n# good line/)

    AnnotateRoutes.do_annotate
  end


end
