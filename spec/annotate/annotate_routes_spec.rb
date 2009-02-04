require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'annotate/annotate_routes'

describe AnnotateRoutes do

  def mock_file(stubs={})
    @mock_file ||= mock(File, stubs)
  end

  describe "Annotate Job" do

    before(:each) do
      File.should_receive(:join).with("config", "routes.rb").and_return("config/routes.rb")
    end

    it "should check if routes.rb exists" do
      File.should_receive(:exists?).with("config/routes.rb").and_return(false)
      AnnotateRoutes.should_receive(:puts).with("Can`t find routes.rb")
      AnnotateRoutes.do_annotate
    end

    describe "When Annotating" do

      before(:each) do
        File.should_receive(:exists?).with("config/routes.rb").and_return(true)
        AnnotateRoutes.should_receive(:`).with("rake routes").and_return("bad line\ngood line")
        File.should_receive(:open).with("config/routes.rb", "wb").and_yield(mock_file)
        AnnotateRoutes.should_receive(:puts).with("Route file annotated.")
      end

      it "should annotate and add a newline!" do
        File.should_receive(:read).with("config/routes.rb").and_return("ActionController::Routing...\nfoo")
        @mock_file.should_receive(:puts).with(/ActionController::Routing...\nfoo\n#== Route Map\n# Generated on .*\n#\n# good line/)
        AnnotateRoutes.do_annotate
      end

      it "should not add a newline if there are empty lines" do
        File.should_receive(:read).with("config/routes.rb").and_return("ActionController::Routing...\nfoo\n")
        @mock_file.should_receive(:puts).with(/ActionController::Routing...\nfoo\n#== Route Map\n# Generated on .*\n#\n# good line/)
        AnnotateRoutes.do_annotate
      end

    end

  end

end
