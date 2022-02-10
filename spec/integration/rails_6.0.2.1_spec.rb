require 'bundler'
require 'rspec'
require 'git'
require_relative 'integration_helper'

describe 'Integration testing on Rails 6.0.2.1', if: IntegrationHelper.able_to_run?(__FILE__, RUBY_VERSION) do
  ::RAILS_6_0_APP_NAME = 'rails_6.0.2.1'.freeze
  ::RAILS_6_0_PROJECT_PATH = File.expand_path('../..', __dir__).freeze
  ::RAILS_6_0_APP_PATH = File.expand_path(RAILS_6_0_APP_NAME, __dir__).freeze

  let!(:git) { Git.open(RAILS_6_0_PROJECT_PATH) }
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

  before(:all) do
    Bundler.with_clean_env do
      Dir.chdir RAILS_6_0_APP_PATH do
        puts `bundle install`
        puts `bin/rails db:migrate`
      end
    end
  end

  around(:each) do |example|
    Bundler.with_clean_env do
      Dir.chdir RAILS_6_0_APP_PATH do
        example.run
      end
    end
  end

  after(:each) do
    git.reset_hard
  end

  describe 'annotate --models' do
    let(:command) { 'bundle exec annotate --models' }

    it 'annotate models' do
      expect(git.diff.any?).to be_falsy

      puts `#{command}`

      expect(git.diff.entries).to contain_exactly(
                                      an_object_having_attributes(task_model),
                                      an_object_having_attributes(task_test),
                                      an_object_having_attributes(task_fixture)
                                  )
    end
  end

  describe 'annotate --routes' do
    let(:command) { 'bundle exec annotate --routes' }

    let(:task_routes) do
      task_routes_diff = <<-DIFF
+# == Route Map
+#
+#                                Prefix Verb   URI Pattern                                                                              Controller#Action
+#                                 tasks GET    /tasks(.:format)                                                                         tasks#index
+#                                       POST   /tasks(.:format)                                                                         tasks#create
+#                              new_task GET    /tasks/new(.:format)                                                                     tasks#new
+#                             edit_task GET    /tasks/:id/edit(.:format)                                                                tasks#edit
+#                                  task GET    /tasks/:id(.:format)                                                                     tasks#show
+#                                       PATCH  /tasks/:id(.:format)                                                                     tasks#update
+#                                       PUT    /tasks/:id(.:format)                                                                     tasks#update
+#                                       DELETE /tasks/:id(.:format)                                                                     tasks#destroy
      DIFF

      default_routes_diff = <<-DIFF
+#         rails_mandrill_inbound_emails POST   /rails/action_mailbox/mandrill/inbound_emails(.:format)                                  action_mailbox/ingresses/mandrill/inbound_emails#create
+#         rails_postmark_inbound_emails POST   /rails/action_mailbox/postmark/inbound_emails(.:format)                                  action_mailbox/ingresses/postmark/inbound_emails#create
+#            rails_relay_inbound_emails POST   /rails/action_mailbox/relay/inbound_emails(.:format)                                     action_mailbox/ingresses/relay/inbound_emails#create
+#         rails_sendgrid_inbound_emails POST   /rails/action_mailbox/sendgrid/inbound_emails(.:format)                                  action_mailbox/ingresses/sendgrid/inbound_emails#create
+#          rails_mailgun_inbound_emails POST   /rails/action_mailbox/mailgun/inbound_emails/mime(.:format)                              action_mailbox/ingresses/mailgun/inbound_emails#create
+#        rails_conductor_inbound_emails GET    /rails/conductor/action_mailbox/inbound_emails(.:format)                                 rails/conductor/action_mailbox/inbound_emails#index
+#                                       POST   /rails/conductor/action_mailbox/inbound_emails(.:format)                                 rails/conductor/action_mailbox/inbound_emails#create
+#     new_rails_conductor_inbound_email GET    /rails/conductor/action_mailbox/inbound_emails/new(.:format)                             rails/conductor/action_mailbox/inbound_emails#new
+#    edit_rails_conductor_inbound_email GET    /rails/conductor/action_mailbox/inbound_emails/:id/edit(.:format)                        rails/conductor/action_mailbox/inbound_emails#edit
+#         rails_conductor_inbound_email GET    /rails/conductor/action_mailbox/inbound_emails/:id(.:format)                             rails/conductor/action_mailbox/inbound_emails#show
+#                                       PATCH  /rails/conductor/action_mailbox/inbound_emails/:id(.:format)                             rails/conductor/action_mailbox/inbound_emails#update
+#                                       PUT    /rails/conductor/action_mailbox/inbound_emails/:id(.:format)                             rails/conductor/action_mailbox/inbound_emails#update
+#                                       DELETE /rails/conductor/action_mailbox/inbound_emails/:id(.:format)                             rails/conductor/action_mailbox/inbound_emails#destroy
+# rails_conductor_inbound_email_reroute POST   /rails/conductor/action_mailbox/:inbound_email_id/reroute(.:format)                      rails/conductor/action_mailbox/reroutes#create
+#                    rails_service_blob GET    /rails/active_storage/blobs/:signed_id/*filename(.:format)                               active_storage/blobs#show
+#             rails_blob_representation GET    /rails/active_storage/representations/:signed_blob_id/:variation_key/*filename(.:format) active_storage/representations#show
+#                    rails_disk_service GET    /rails/active_storage/disk/:encoded_key/*filename(.:format)                              active_storage/disk#show
+#             update_rails_disk_service PUT    /rails/active_storage/disk/:encoded_token(.:format)                                      active_storage/disk#update
+#                  rails_direct_uploads POST   /rails/active_storage/direct_uploads(.:format)                                           active_storage/direct_uploads#create
      DIFF


      path = 'config/routes.rb'
      {
          path: include(path),
          patch: include(task_routes_diff, default_routes_diff)
      }
    end

    it 'annotate routes.rb' do
      expect(git.diff.any?).to be_falsy

      puts `#{command}`

      expect(git.diff.entries).to contain_exactly(an_object_having_attributes(task_routes))
    end
  end

  describe 'rails g annotate:install' do
    let(:command) { 'bin/rails g annotate:install' }
    let(:rake_file_path) { 'lib/tasks/auto_annotate_models.rake' }
    let(:full_path) { File.expand_path(rake_file_path) }

    after(:each) do
      File.delete(full_path)
    end

    it 'generates the rake file' do
      expect { `#{command}` }.to change { File.exist?(rake_file_path) }.from(false).to(true)
    end

    context 'with multi-db environment' do
      let(:migrate_command) { 'bin/rails db:migrate:primary' }

      it 'hooks database-specific commands and annotates models' do
        expect(git.diff.any?).to be_falsy

        system({ 'MULTI_DB' => 'true' }, command)
        system({ 'MULTI_DB' => 'true' }, migrate_command)

        expect(git.diff.entries).to contain_exactly(
                                        an_object_having_attributes(task_model),
                                        an_object_having_attributes(task_test),
                                        an_object_having_attributes(task_fixture)
                                    )
      end
    end
  end
end
