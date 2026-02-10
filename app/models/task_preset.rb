class TaskPreset < ApplicationRecord
  has_many :task_preset_items, dependent: :destroy
  accepts_nested_attributes_for :task_preset_items, allow_destroy: true

  enum :task_type, { onboarding: "onboarding", offboarding: "offboarding", transfer: "transfer" }

  validates :name, presence: true
  validates :task_type, presence: true
end
