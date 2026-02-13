class SaasAccount < ApplicationRecord
  include Auditable

  belongs_to :saas
  belongs_to :user
  has_many :survey_responses, dependent: :nullify

  enum :status, { active: "active", suspended: "suspended", deleted: "deleted" }

  validates :saas_id, uniqueness: { scope: :user_id }
end
