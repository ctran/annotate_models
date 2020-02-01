require 'bundler'
require 'rspec'
require 'pry'
require 'bundler/cli/install'
require 'git'

describe 'annotate Rails' do
  let(:app_name) { 'rails_6.0.2.1' }

  let(:project_path) { File.expand_path('../..', __dir__) }
  let!(:app_path) { File.expand_path(app_name, __dir__) }

  let!(:git) { Git.open(project_path) }

  let(:command) { 'bundle exec annotate --models' }

  let(:task_model) do
    patch = <<~PATCH
      +# == Schema Information
      +#
      +# Table name: tasks
      +#
      +#  id         :integer          not null, primary key
      +#  content    :string
      +#  count      :integer          default("0")
      +#  status     :boolean          default("0")
      +#  created_at :datetime         not null
      +#  updated_at :datetime         not null
      +#
    PATCH

    path = 'app/models/task.rb'
    {
      path: include(path),
      patch: include(patch)
    }
  end
  let(:task_test) do
    patch = <<~PATCH
      +# == Schema Information
      +#
      +# Table name: tasks
      +#
      +#  id         :integer          not null, primary key
      +#  content    :string
      +#  count      :integer          default("0")
      +#  status     :boolean          default("0")
      +#  created_at :datetime         not null
      +#  updated_at :datetime         not null
      +#
    PATCH

    path = 'test/models/task_test.rb'
    {
      path: include(path),
      patch: include(patch)
    }
  end
  let(:task_fixture) do
    patch = <<~PATCH
      +# == Schema Information
      +#
      +# Table name: tasks
      +#
      +#  id         :integer          not null, primary key
      +#  content    :string
      +#  count      :integer          default("0")
      +#  status     :boolean          default("0")
      +#  created_at :datetime         not null
      +#  updated_at :datetime         not null
      +#
    PATCH

    path = 'test/fixtures/tasks.yml'
    {
      path: include(path),
      patch: include(patch)
    }
  end

  before do
    # ensure bundle install
  end

  after do
    git.reset_hard
  end

  it 'annotate models' do
    puts "project_path: #{project_path}"
    puts "app_path: #{project_path}"

    puts "Dir.pwd: #{Dir.pwd}"
    puts "__dir__: #{__dir__}"
    puts "__FILE__: #{__FILE__}"

    Bundler.with_clean_env do
      puts "app_path: #{app_path}"
      Dir.chdir app_path do
        puts 'inside Dir.chdir'
        puts "Dir.pwd: #{Dir.pwd}"
        puts "__dir__: #{__dir__}"
        puts "__FILE__: #{__FILE__}"

        expect(git.diff.any?).to be_falsy

        `#{command}`

        expect(git.diff.entries).to contain_exactly(
          an_object_having_attributes(task_model),
          an_object_having_attributes(task_test),
          an_object_having_attributes(task_fixture)
        )
      end
    end
  end
end
