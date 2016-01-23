require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'annotate/annotate_routes'

describe AnnotateRoutes do
  ROUTE_FILE = 'config/routes.rb'
  ANNOTATION_ADDED = "#{ROUTE_FILE} annotated."
  ANNOTATION_REMOVED = "Removed annotations from #{ROUTE_FILE}."
  FILE_UNCHANGED = "#{ROUTE_FILE} unchanged."

  def mock_file(stubs={})
    @mock_file ||= double(File, stubs)
  end

  it 'should check if routes.rb exists' do
    expect(File).to receive(:exists?).with(ROUTE_FILE).and_return(false)
    expect(AnnotateRoutes).to receive(:puts).with("Can't find routes.rb")
    AnnotateRoutes.do_annotations
  end

  describe 'When adding' do
    before(:each) do
      expect(File).to receive(:exists?).with(ROUTE_FILE).and_return(true)
      expect(AnnotateRoutes).to receive(:`).with('rake routes').and_return('')
    end

    it 'should insert annotations if file does not contain annotations' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return("")
      expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
      expect(@mock_file).to receive(:puts).with("\n# == Route Map\n#\n")
      expect(AnnotateRoutes).to receive(:puts).with(ANNOTATION_ADDED)

      AnnotateRoutes.do_annotations
    end

    it 'should skip annotations if file does already contain annotation' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return("\n# == Route Map\n#\n")
      expect(AnnotateRoutes).to receive(:puts).with(FILE_UNCHANGED)

      AnnotateRoutes.do_annotations
    end
  end

  describe 'When adding with older Rake versions' do
    before(:each) do
      expect(File).to receive(:exists?).with(ROUTE_FILE).and_return(true)
      expect(AnnotateRoutes).to receive(:`).with('rake routes').and_return("(in /bad/line)\ngood line")
      expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
      expect(AnnotateRoutes).to receive(:puts).with(ANNOTATION_ADDED)
    end

    it 'should annotate and add a newline!' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return("ActionController::Routing...\nfoo")
      expect(@mock_file).to receive(:puts).with(/ActionController::Routing...\nfoo\n\n# == Route Map\n#\n# good line\n/)
      AnnotateRoutes.do_annotations
    end

    it 'should not add a newline if there are empty lines' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return("ActionController::Routing...\nfoo\n")
      expect(@mock_file).to receive(:puts).with(/ActionController::Routing...\nfoo\n\n# == Route Map\n#\n# good line\n/)
      AnnotateRoutes.do_annotations
    end
  end

  describe 'When adding with newer Rake versions' do
    before(:each) do
      expect(File).to receive(:exists?).with(ROUTE_FILE).and_return(true)
      expect(AnnotateRoutes).to receive(:`).with("rake routes").and_return("another good line\ngood line")
      expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
      expect(AnnotateRoutes).to receive(:puts).with(ANNOTATION_ADDED)
    end

    it 'should annotate and add a newline!' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return("ActionController::Routing...\nfoo")
      expect(@mock_file).to receive(:puts).with(/ActionController::Routing...\nfoo\n\n# == Route Map\n#\n# another good line\n# good line\n/)
      AnnotateRoutes.do_annotations
    end

    it 'should not add a newline if there are empty lines' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return("ActionController::Routing...\nfoo\n")
      expect(@mock_file).to receive(:puts).with(/ActionController::Routing...\nfoo\n\n# == Route Map\n#\n# another good line\n# good line\n/)
      AnnotateRoutes.do_annotations
    end

    it 'should add a timestamp when :timestamp is passed' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return("ActionController::Routing...\nfoo")
      expect(@mock_file).to receive(:puts).with(/ActionController::Routing...\nfoo\n\n# == Route Map \(Updated \d{4}-\d{2}-\d{2} \d{2}:\d{2}\)\n#\n# another good line\n# good line\n/)
      AnnotateRoutes.do_annotations :timestamp => true
    end
  end

  describe 'When removing' do
    before(:each) do
      expect(File).to receive(:exists?).with(ROUTE_FILE).and_return(true)
      expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
      expect(AnnotateRoutes).to receive(:puts).with(ANNOTATION_REMOVED)
    end

    it 'should remove trailing annotation and trim trailing newlines, but leave leading newlines alone' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nActionController::Routing...\nfoo\n\n\n\n\n\n\n\n\n\n\n# == Route Map\n#\n# another good line\n# good line\n")
      expect(@mock_file).to receive(:puts).with(/\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nActionController::Routing...\nfoo\n/)
      AnnotateRoutes.remove_annotations
    end

    it 'should remove prepended annotation and trim leading newlines, but leave trailing newlines alone' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return("# == Route Map\n#\n# another good line\n# good line\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nActionController::Routing...\nfoo\n\n\n\n\n\n\n\n\n\n\n")
      expect(@mock_file).to receive(:puts).with(/ActionController::Routing...\nfoo\n\n\n\n\n\n\n\n\n\n\n/)
      AnnotateRoutes.remove_annotations
    end
  end
end
