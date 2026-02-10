class Survey < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  has_many :survey_responses, dependent: :destroy

  enum :survey_type, { account_review: "account_review", password_update: "password_update" }
  enum :status, { draft: "draft", active: "active", closed: "closed" }

  validates :title, presence: true

  def response_rate
    return 0 if target_user_count.zero?
    (responded_user_count.to_f / target_user_count * 100).round(1)
  end

  def target_user_count
    survey_responses.select(:user_id).distinct.count
  end

  def responded_user_count
    survey_responses.where.not(responded_at: nil).select(:user_id).distinct.count
  end
end
