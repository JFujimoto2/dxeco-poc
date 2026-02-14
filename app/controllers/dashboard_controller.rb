class DashboardController < ApplicationController
  def index
    @saas_count = Saas.count
    @user_count = User.count
    @account_count = SaasAccount.active.count
    @attention_count = Saas.cancelled.count + SaasAccount.where.not(status: "active").count
    @pending_approval_count = ApprovalRequest.pending.count
    @active_task_count = Task.where.not(status: "completed").count
    @active_survey_count = Survey.active.count
    @recent_audit_logs = AuditLog.includes(:user).recent.limit(5)

    @expiring_contracts = SaasContract.expiring_soon.includes(:saas).order(:expires_on)
    @expired_contracts_count = SaasContract.expired.count

    @password_expired_users = User.password_expired.order(:last_password_change_at)
    @password_expiring_users = User.password_expiring_soon.order(:last_password_change_at)

    contracts = SaasContract.includes(:saas).where.not(price_cents: nil)
    @total_monthly_cost = contracts.sum(&:monthly_cost_cents)
    @total_annual_cost = contracts.sum(&:annual_cost_cents)
    @cost_by_category = contracts.group_by { |c| c.saas.category || "未分類" }
      .transform_values { |cs| cs.sum(&:monthly_cost_cents) }
      .sort_by { |_, v| -v }
  end
end
