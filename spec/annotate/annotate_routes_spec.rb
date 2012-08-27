require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'annotate/annotate_routes'

describe AnnotateRoutes do

  def mock_file(stubs={})
    @mock_file ||= mock(File, stubs)
  end

  it "should check if routes.rb exists" do
    File.should_receive(:exists?).with("config/routes.rb").and_return(false)
    AnnotateRoutes.should_receive(:puts).with("Can`t find routes.rb")
    AnnotateRoutes.do_annotations
  end

  describe "When Annotating, with older Rake Versions" do

    before(:each) do
      File.should_receive(:exists?).with("config/routes.rb").and_return(true)
      AnnotateRoutes.should_receive(:`).with("rake routes").and_return("(in /bad/line)\ngood line")
      File.should_receive(:open).with("config/routes.rb", "wb").and_yield(mock_file)
      AnnotateRoutes.should_receive(:puts).with("Route file annotated.")
    end

    it "should annotate and add a newline!" do
      File.should_receive(:read).with("config/routes.rb").and_return("ActionController::Routing...\nfoo")
      @mock_file.should_receive(:puts).with(/ActionController::Routing...\nfoo\n\n# == Route Map \(Updated \d{4}-\d{2}-\d{2} \d{2}:\d{2}\)\n#\n# good line\n/)
      AnnotateRoutes.do_annotations
    end

    it "should not add a newline if there are empty lines" do
      File.should_receive(:read).with("config/routes.rb").and_return("ActionController::Routing...\nfoo\n")
      @mock_file.should_receive(:puts).with(/ActionController::Routing...\nfoo\n\n# == Route Map \(Updated \d{4}-\d{2}-\d{2} \d{2}:\d{2}\)\n#\n# good line\n/)
      AnnotateRoutes.do_annotations
    end

  end

  describe "When Annotating, with newer Rake Versions" do

    before(:each) do
      File.should_receive(:exists?).with("config/routes.rb").and_return(true)
      AnnotateRoutes.should_receive(:`).with("rake routes").and_return("another good line\ngood line")
      File.should_receive(:open).with("config/routes.rb", "wb").and_yield(mock_file)
      AnnotateRoutes.should_receive(:puts).with("Route file annotated.")
    end

    it "should annotate and add a newline!" do
      File.should_receive(:read).with("config/routes.rb").and_return("ActionController::Routing...\nfoo")
      @mock_file.should_receive(:puts).with(/ActionController::Routing...\nfoo\n\n# == Route Map \(Updated \d{4}-\d{2}-\d{2} \d{2}:\d{2}\)\n#\n# another good line\n# good line\n/)
      AnnotateRoutes.do_annotations
    end

    it "should not add a newline if there are empty lines" do
      File.should_receive(:read).with("config/routes.rb").and_return("ActionController::Routing...\nfoo\n")
      @mock_file.should_receive(:puts).with(/ActionController::Routing...\nfoo\n\n# == Route Map \(Updated \d{4}-\d{2}-\d{2} \d{2}:\d{2}\)\n#\n# another good line\n# good line\n/)
      AnnotateRoutes.do_annotations
    end

  end

  describe "When Removing Annotation" do

    before(:each) do
      File.should_receive(:exists?).with("config/routes.rb").and_return(true)
      File.should_receive(:open).with("config/routes.rb", "wb").and_yield(mock_file)
      AnnotateRoutes.should_receive(:puts).with("Removed annotations from routes file.")
    end

    it "should remove trailing annotation and trim trailing newlines, but leave leading newlines alone" do
      File.should_receive(:read).with("config/routes.rb").and_return("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nActionController::Routing...\nfoo\n\n\n\n\n\n\n\n\n\n\n# == Route Map (Updated 2012-08-16 00:00)\n#\n# another good line\n# good line\n")
      @mock_file.should_receive(:puts).with(/\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nActionController::Routing...\nfoo\n/)
      AnnotateRoutes.remove_annotations
    end

    it "should remove prepended annotation and trim leading newlines, but leave trailing newlines alone" do
      File.should_receive(:read).with("config/routes.rb").and_return("# == Route Map (Updated 2012-08-16 00:00)\n#\n# another good line\n# good line\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nActionController::Routing...\nfoo\n\n\n\n\n\n\n\n\n\n\n")
      @mock_file.should_receive(:puts).with(/ActionController::Routing...\nfoo\n\n\n\n\n\n\n\n\n\n\n/)
      AnnotateRoutes.remove_annotations
    end

  end

end
