require_relative '../../spec_helper'

describe 'annotate_models rake task and Annotate.set_defaults' do
  before do
    Rake.application = Rake::Application.new
    Rake::Task.define_task('environment')
    Rake.load_rakefile('tasks/annotate_models.rake')
  end

  let(:annotate_models_argument) do
    argument = nil
    expect(AnnotateModels).to receive(:do_annotations) { |arg| argument = arg }
    Rake::Task['annotate_models'].invoke
    argument
  end

  describe 'with_comment_column' do
    after { ENV.delete('with_comment_column') }
    subject { annotate_models_argument[:with_comment_column] }

    context 'when Annotate.set_defaults is not called (defaults)' do
      it { is_expected.to be_falsey }
    end

    context 'when Annotate.set_defaults sets it to "true"' do
      before { Annotate.set_defaults('with_comment_column' => 'true') }
      it { is_expected.to be_truthy }
    end
  end
end