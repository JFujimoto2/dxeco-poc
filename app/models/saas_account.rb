class SaasAccount < ApplicationRecord
  include Auditable

  belongs_to :saas
  belongs_to :user
  has_many :survey_responses, dependent: :nullify

  enum :status, { active: "active", suspended: "suspended", deleted: "deleted" }
  enum :role, { member: "member", admin: "admin", owner: "owner" }

  validates :saas_id, uniqueness: { scope: :user_id }

  scope :filter_by_saas, ->(saas_id) { saas_id.present? ? where(saas_id: saas_id) : all }
  scope :filter_by_user, ->(user_id) { user_id.present? ? where(user_id: user_id) : all }
  scope :filter_by_status, ->(status) { status.present? ? where(status: status) : all }
end
