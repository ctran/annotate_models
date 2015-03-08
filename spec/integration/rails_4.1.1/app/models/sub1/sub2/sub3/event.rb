# == Schema Information
#
# Table name: events
#
#  id         :integer          not null, primary key
#  content    :string(255)
#  created_at :datetime
#  updated_at :datetime
#

module Sub1::Sub2::Sub3
	class Event < ActiveRecord::Base
	end
end
