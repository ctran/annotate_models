class Task < ActiveRecord::Base
	enum status: %w(normal active completed)
end
