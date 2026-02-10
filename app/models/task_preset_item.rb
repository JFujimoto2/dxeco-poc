class TaskPresetItem < ApplicationRecord
  belongs_to :task_preset
  belongs_to :default_assignee, class_name: "User", optional: true

  validates :action_type, presence: true
  validates :description, presence: true
end
