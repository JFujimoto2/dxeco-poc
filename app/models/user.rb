class User < ApplicationRecord
  include Auditable

  has_many :saas_accounts, dependent: :destroy
  has_many :saases, through: :saas_accounts
  has_many :owned_saases, class_name: "Saas", foreign_key: :owner_id, dependent: :nullify

  enum :role, { viewer: "viewer", manager: "manager", admin: "admin" }

  validates :entra_id_sub, presence: true, uniqueness: true
  validates :email, presence: true
  validates :role, presence: true

  scope :search_by_name, ->(q) { where("display_name ILIKE ? OR email ILIKE ?", "%#{q}%", "%#{q}%") if q.present? }
  scope :filter_by_department, ->(d) { where(department: d) if d.present? }
end
