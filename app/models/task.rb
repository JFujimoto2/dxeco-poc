class Task < ApplicationRecord
  include Auditable

  belongs_to :target_user, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User"
  has_many :task_items, dependent: :destroy
  accepts_nested_attributes_for :task_items, allow_destroy: true

  enum :task_type, { onboarding: "onboarding", offboarding: "offboarding", transfer: "transfer", account_cleanup: "account_cleanup" }
  enum :status, { open: "open", in_progress: "in_progress", completed: "completed" }

  validates :title, presence: true
  validates :task_type, presence: true

  def completion_rate
    items = task_items.loaded? ? task_items : task_items.to_a
    return 0 if items.empty?
    completed = items.count(&:completed?)
    (completed.to_f / items.size * 100).round(1)
  end
end
