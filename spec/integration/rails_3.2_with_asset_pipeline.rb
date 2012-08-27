require 'common_validation'

module Annotate
  module Validations
    class Rails32WithAssetPipeline < Base
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
    end
  end
end
