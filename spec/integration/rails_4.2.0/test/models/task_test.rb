# == Schema Information
#
# Table name: tasks
#
#  id         :integer          not null, primary key
#  content    :string
#  count      :integer          default(0)
#  status     :boolean          default(FALSE)
#  created_at :datetime
#  updated_at :datetime
#

require 'test_helper'

class TaskTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
