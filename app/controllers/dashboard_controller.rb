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
  end
end
