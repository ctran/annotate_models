require 'bundler'
require 'rspec'
require 'git'
require_relative 'integration_helper'

describe 'Integration testing on Rails 5.2.5', if: IntegrationHelper.able_to_run?(__FILE__, RUBY_VERSION) do
  ::RAILS_5_2_APP_NAME = 'rails_5.2.5'.freeze
  ::RAILS_5_2_PROJECT_PATH = File.expand_path('../..', __dir__).freeze
  ::RAILS_5_2_APP_PATH = File.expand_path(RAILS_5_2_APP_NAME, __dir__).freeze

  let!(:git) { Git.open(RAILS_5_2_PROJECT_PATH) }

  before(:all) do
    Bundler.with_clean_env do
      Dir.chdir RAILS_5_2_APP_PATH do
        `bundle install`
        `bin/rails db:migrate`
      end
    end
  end

  around(:each) do |example|
    Bundler.with_clean_env do
      Dir.chdir RAILS_5_2_APP_PATH do
        example.run
      end
    end

    git.reset_hard
  end

  describe 'annotate --models' do
    let(:task_model) do
      patch = <<~PATCH
        +# == Schema Information
        +#
        +# Table name: tasks
        +#
        +#  id         :integer          not null, primary key
        +#  content    :string
        +#  count      :integer          default(0)
        +#  status     :boolean          default(FALSE)
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
        +#  count      :integer          default(0)
        +#  status     :boolean          default(FALSE)
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
        +#  count      :integer          default(0)
        +#  status     :boolean          default(FALSE)
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

    subject do
      `bundle exec annotate --models`
    end

    it 'annotate models' do
      expect { subject }.to change { git.diff }.from(be_blank).to(be_present).
        and(change { git.diff.entries }.from(be_blank).to(contain_exactly(
          an_object_having_attributes(task_model),
          an_object_having_attributes(task_test),
          an_object_having_attributes(task_fixture)
        )))
    end
  end

  describe 'annotate --routes' do
    let(:task_routes) do
      task_routes_diff = <<-DIFF
+# == Route Map
+#
+#                    Prefix Verb   URI Pattern                                                                              Controller#Action
+#                     tasks GET    /tasks(.:format)                                                                         tasks#index
+#                           POST   /tasks(.:format)                                                                         tasks#create
+#                  new_task GET    /tasks/new(.:format)                                                                     tasks#new
+#                 edit_task GET    /tasks/:id/edit(.:format)                                                                tasks#edit
+#                      task GET    /tasks/:id(.:format)                                                                     tasks#show
+#                           PATCH  /tasks/:id(.:format)                                                                     tasks#update
+#                           PUT    /tasks/:id(.:format)                                                                     tasks#update
+#                           DELETE /tasks/:id(.:format)                                                                     tasks#destroy
      DIFF

      default_routes_diff = <<-DIFF
+#        rails_service_blob GET    /rails/active_storage/blobs/:signed_id/*filename(.:format)                               active_storage/blobs#show
+# rails_blob_representation GET    /rails/active_storage/representations/:signed_blob_id/:variation_key/*filename(.:format) active_storage/representations#show
+#        rails_disk_service GET    /rails/active_storage/disk/:encoded_key/*filename(.:format)                              active_storage/disk#show
+# update_rails_disk_service PUT    /rails/active_storage/disk/:encoded_token(.:format)                                      active_storage/disk#update
+#      rails_direct_uploads POST   /rails/active_storage/direct_uploads(.:format)                                           active_storage/direct_uploads#create
      DIFF

      path = 'config/routes.rb'
      {
          path: include(path),
          patch: include(task_routes_diff, default_routes_diff)
      }
    end

    subject do
      `bundle exec annotate --routes`
    end

    subject do
      puts `#{command}`
    end

    it 'annotate routes' do
      expect { subject }.to change { git.diff }.from(be_blank).to(be_present).
        and(change { git.diff.entries }.from(be_blank).to(contain_exactly(
          an_object_having_attributes(task_routes)
        )))
    end
  end

  describe 'rails g annotate:install' do
    let(:rake_file_path) { 'lib/tasks/auto_annotate_models.rake' }
    let(:rake_file_full_path) { File.expand_path(rake_file_path) }

    subject do
      `bin/rails g annotate:install`
    end

    after(:each) do
      File.delete(rake_file_full_path)
    end

    it 'generates the rake file' do
      expect { subject }.to change { File.exist?(rake_file_path) }.from(false).to(true)
    end
  end
end
