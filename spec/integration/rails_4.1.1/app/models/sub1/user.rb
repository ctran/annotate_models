# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  content    :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Sub1::User < ActiveRecord::Base
end
