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

    @total_monthly_cost = SaasContract.total_monthly_cost
    @total_annual_cost = SaasContract.total_annual_cost
    @cost_by_category = SaasContract.monthly_cost_by_category
  end
end
