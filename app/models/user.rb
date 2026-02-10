class User < ApplicationRecord
  enum :role, { viewer: "viewer", manager: "manager", admin: "admin" }

  validates :entra_id_sub, presence: true, uniqueness: true
  validates :email, presence: true
  validates :role, presence: true
end
