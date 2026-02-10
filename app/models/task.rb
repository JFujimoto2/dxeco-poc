class Task < ApplicationRecord
  include Auditable

  belongs_to :target_user, class_name: "User"
  belongs_to :created_by, class_name: "User"
  has_many :task_items, dependent: :destroy
  accepts_nested_attributes_for :task_items, allow_destroy: true

  enum :task_type, { onboarding: "onboarding", offboarding: "offboarding", transfer: "transfer" }
  enum :status, { open: "open", in_progress: "in_progress", completed: "completed" }

  validates :title, presence: true
  validates :task_type, presence: true

  def completion_rate
    return 0 if task_items.count.zero?
    (task_items.where(status: "completed").count.to_f / task_items.count * 100).round(1)
  end
end
