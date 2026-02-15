class SaasContract < ApplicationRecord
  belongs_to :saas

  validates :saas_id, uniqueness: true

  scope :expiring_soon, ->(days = 30) { where(expires_on: Date.current..days.days.from_now.to_date) }
  scope :expired, -> { where("expires_on < ?", Date.current) }

  UNCATEGORIZED_LABEL = "未分類".freeze
  MONTHLY_COST_SQL = "CASE WHEN billing_cycle = 'yearly' THEN COALESCE(price_cents, 0) / 12 ELSE COALESCE(price_cents, 0) END".freeze
  ANNUAL_COST_SQL = "CASE WHEN billing_cycle = 'yearly' THEN COALESCE(price_cents, 0) ELSE COALESCE(price_cents, 0) * 12 END".freeze

  scope :with_cost, -> { where.not(price_cents: nil) }

  def self.total_monthly_cost
    with_cost.sum(Arel.sql(MONTHLY_COST_SQL))
  end

  def self.total_annual_cost
    with_cost.sum(Arel.sql(ANNUAL_COST_SQL))
  end

  def self.monthly_cost_by_category
    with_cost.joins(:saas)
             .group(Arel.sql("COALESCE(saases.category, '#{UNCATEGORIZED_LABEL}')"))
             .sum(Arel.sql(MONTHLY_COST_SQL))
             .sort_by { |_, v| -v }
  end

  def monthly_cost_cents
    billing_cycle == "yearly" ? (price_cents || 0) / 12 : (price_cents || 0)
  end

  def annual_cost_cents
    billing_cycle == "yearly" ? (price_cents || 0) : (price_cents || 0) * 12
  end
end
