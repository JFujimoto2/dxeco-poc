class SurveyResponse < ApplicationRecord
  belongs_to :survey
  belongs_to :user
  belongs_to :saas_account, optional: true

  validates :survey_id, uniqueness: { scope: [ :user_id, :saas_account_id ] }

  scope :pending, -> { where(responded_at: nil) }
  scope :responded, -> { where.not(responded_at: nil) }
  scope :not_using, -> { where(response: "not_using") }
end
