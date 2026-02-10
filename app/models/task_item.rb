class TaskItem < ApplicationRecord
  include Auditable

  belongs_to :task
  belongs_to :saas, class_name: "Saas", optional: true
  belongs_to :assignee, class_name: "User", optional: true

  enum :status, { pending: "pending", completed: "completed" }

  validates :action_type, presence: true
  validates :description, presence: true

  def complete!
    update!(status: :completed, completed_at: Time.current)
  end
end
