require 'bundler'
require 'rspec'
require 'git'
require_relative 'integration_helper'

describe 'Integration testing on Rails 5.2.4.1', if: IntegrationHelper.able_to_run?(__FILE__, RUBY_VERSION) do
  let(:app_name) { 'rails_5.2.4.1' }

  let(:project_path) { File.expand_path('../..', __dir__) }
  let!(:app_path) { File.expand_path(app_name, __dir__) }

  let!(:git) { Git.open(project_path) }

  let(:migration_command) { 'bin/rails db:migrate' }

  before do
    Bundler.with_clean_env do
      Dir.chdir app_path do
        puts `bundle install`
        puts `#{migration_command}`
      end
    end
  end

  after do
    git.reset_hard
  end

  describe 'annotate --models' do
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

    it 'annotate models' do
      Bundler.with_clean_env do
        Dir.chdir app_path do
          expect(git.diff.any?).to be_falsy

          puts `#{command}`

          expect(git.diff.entries).to contain_exactly(
                                          an_object_having_attributes(task_model),
                                          an_object_having_attributes(task_test),
                                          an_object_having_attributes(task_fixture)
                                      )
        end
      end
    end
  end

  describe 'annotate --routes' do
    let(:command) { 'bundle exec annotate --routes' }

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

    it 'annotate routes.rb' do
      Bundler.with_clean_env do
        Dir.chdir app_path do
          expect(git.diff.any?).to be_falsy

          puts `#{command}`

          expect(git.diff.entries).to include(
                                          an_object_having_attributes(task_routes)
                                      )
        end
      end
    end
  end
end
