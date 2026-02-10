class AuditLog < ApplicationRecord
  belongs_to :user, optional: true

  validates :action, presence: true
  validates :resource_type, presence: true
  validates :resource_id, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_resource_type, ->(type) { where(resource_type: type) if type.present? }
  scope :by_user, ->(user_id) { where(user_id: user_id) if user_id.present? }
  scope :by_date_range, ->(from, to) {
    scope = all
    scope = scope.where("created_at >= ?", Date.parse(from.to_s).beginning_of_day) if from.present?
    scope = scope.where("created_at <= ?", Date.parse(to.to_s).end_of_day) if to.present?
    scope
  }
end
