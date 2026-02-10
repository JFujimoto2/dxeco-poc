class Saas < ApplicationRecord
  belongs_to :owner, class_name: "User", optional: true
  has_one :saas_contract, dependent: :destroy
  has_many :saas_accounts, dependent: :destroy
  has_many :users, through: :saas_accounts

  enum :status, { active: "active", trial: "trial", cancelled: "cancelled" }

  validates :name, presence: true

  accepts_nested_attributes_for :saas_contract, update_only: true

  scope :search_by_name, ->(q) { where("name ILIKE ?", "%#{q}%") if q.present? }
  scope :filter_by_category, ->(c) { where(category: c) if c.present? }
  scope :filter_by_status, ->(s) { where(status: s) if s.present? }
end
