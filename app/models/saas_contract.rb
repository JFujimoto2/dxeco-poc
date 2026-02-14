class SaasContract < ApplicationRecord
  belongs_to :saas

  validates :saas_id, uniqueness: true

  scope :expiring_soon, ->(days = 30) { where(expires_on: Date.current..days.days.from_now.to_date) }
  scope :expired, -> { where("expires_on < ?", Date.current) }

  def monthly_cost_cents
    billing_cycle == "yearly" ? (price_cents || 0) / 12 : (price_cents || 0)
  end

  def annual_cost_cents
    billing_cycle == "yearly" ? (price_cents || 0) : (price_cents || 0) * 12
  end
end
