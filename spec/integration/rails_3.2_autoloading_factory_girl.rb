require 'common_validation'

module Annotate
  module Validations
    class Rails32AutoloadingFactoryGirl < Base
      def self.schema_annotation
        return <<-RUBY
# == Schema Information
#
# Table name: tasks
#
#  id         :integer          not null, primary key
#  content    :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
RUBY
      end

      def self.route_annotation
        return <<-RUBY
# == Route Map (Updated YYYY-MM-DD HH:MM)
#
#     tasks GET    /tasks(.:format)          tasks#index
#           POST   /tasks(.:format)          tasks#create
#  new_task GET    /tasks/new(.:format)      tasks#new
# edit_task GET    /tasks/:id/edit(.:format) tasks#edit
#      task GET    /tasks/:id(.:format)      tasks#show
#           PUT    /tasks/:id(.:format)      tasks#update
#           DELETE /tasks/:id(.:format)      tasks#destroy
#
RUBY
      end

      def self.verify_files(test_rig)
        return Annotate::Validations::Common.verify_files({
          :model => true,
          :test => true,
          :fixture => false,
          :factory => true,
          :routes => true
        }, test_rig, self.schema_annotation, self.route_annotation, true)
      end
    end
  end
end
