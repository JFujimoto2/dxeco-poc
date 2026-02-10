class SaasAccount < ApplicationRecord
  include Auditable

  belongs_to :saas
  belongs_to :user

  enum :status, { active: "active", suspended: "suspended", deleted: "deleted" }

  validates :saas_id, uniqueness: { scope: :user_id }
end
