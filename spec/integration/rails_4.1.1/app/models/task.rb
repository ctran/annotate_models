# == Schema Information
#
# Table name: tasks
#
#  id         :integer          not null, primary key
#  content    :string(255)
#  count      :integer          default(0)
#  status     :boolean          default(FALSE)
#  created_at :datetime
#  updated_at :datetime
#

class Task < ActiveRecord::Base
	enum status: %w(normal active completed)
end
