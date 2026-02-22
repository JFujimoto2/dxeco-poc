class Saas < ApplicationRecord
  include Auditable

  belongs_to :owner, class_name: "User", optional: true
  has_one :saas_contract, dependent: :destroy
  has_many :saas_accounts, dependent: :destroy
  has_many :users, through: :saas_accounts

  enum :status, { active: "active", trial: "trial", cancelled: "cancelled" }
  enum :auth_method, { sso: "sso", password: "password", mfa: "mfa", other_auth: "other" }
  enum :data_location, { domestic: "domestic", overseas: "overseas", unknown: "unknown" }

  validates :name, presence: true

  accepts_nested_attributes_for :saas_contract, update_only: true

  scope :search_by_name, ->(q) { where("name ILIKE ?", "%#{q}%") if q.present? }
  scope :filter_by_category, ->(c) { where(category: c) if c.present? }
  scope :filter_by_status, ->(s) { where(status: s) if s.present? }
  scope :filter_by_auth_method, ->(m) { where(auth_method: m) if m.present? }
  scope :filter_by_data_location, ->(l) { where(data_location: l) if l.present? }
  scope :filter_by_department, ->(dept) {
    if dept.present?
      joins(saas_accounts: :user).where(users: { department: dept }).distinct
    end
  }
  scope :personal_data_without_sso, -> { where(handles_personal_data: true).where.not(auth_method: "sso") }
  scope :personal_data_overseas, -> { where(handles_personal_data: true, data_location: "overseas") }
end
