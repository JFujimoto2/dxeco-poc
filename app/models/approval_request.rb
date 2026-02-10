class ApprovalRequest < ApplicationRecord
  include Auditable

  belongs_to :requester, class_name: "User"
  belongs_to :saas, class_name: "Saas", optional: true
  belongs_to :approved_by, class_name: "User", optional: true

  enum :request_type, { new_saas: "new_saas", add_account: "add_account", remove_account: "remove_account" }
  enum :status, { pending: "pending", approved: "approved", rejected: "rejected" }

  validates :reason, presence: true
  validates :request_type, presence: true

  def target_saas_name
    saas&.name || saas_name
  end
end
