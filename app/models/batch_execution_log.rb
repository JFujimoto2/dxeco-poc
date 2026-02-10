class BatchExecutionLog < ApplicationRecord
  enum :status, { running: "running", success: "success", failure: "failure" }

  validates :job_name, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
