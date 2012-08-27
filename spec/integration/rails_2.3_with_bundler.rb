require 'common_validation'

module Annotate
  module Validations
    class Rails23WithBundler < Base
      def self.schema_annotation
        return <<-RUBY
# == Schema Information
#
# Table name: tasks
#
#  id         :integer          not null, primary key
#  content    :string(255)
#  created_at :datetime
#  updated_at :datetime
#
RUBY
      end

      def self.route_annotation
        return <<-RUBY
# == Route Map (Updated YYYY-MM-DD HH:MM)
#
#     tasks GET    /tasks(.:format)          {:controller=>"tasks", :action=>"index"}
#           POST   /tasks(.:format)          {:controller=>"tasks", :action=>"create"}
#  new_task GET    /tasks/new(.:format)      {:controller=>"tasks", :action=>"new"}
# edit_task GET    /tasks/:id/edit(.:format) {:controller=>"tasks", :action=>"edit"}
#      task GET    /tasks/:id(.:format)      {:controller=>"tasks", :action=>"show"}
#           PUT    /tasks/:id(.:format)      {:controller=>"tasks", :action=>"update"}
#           DELETE /tasks/:id(.:format)      {:controller=>"tasks", :action=>"destroy"}
#
RUBY
      end
    end
  end
end
