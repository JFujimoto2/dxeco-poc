class SaasContract < ApplicationRecord
  belongs_to :saas

  validates :saas_id, uniqueness: true
end
