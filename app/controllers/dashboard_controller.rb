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

    @personal_data_without_sso = Saas.personal_data_without_sso
    @personal_data_overseas = Saas.personal_data_overseas
    @department_risk = department_risk_data
  end

  private

  def department_risk_data
    risky_saas_ids = Saas.where(handles_personal_data: true).where.not(auth_method: "sso").pluck(:id)
    return [] if risky_saas_ids.empty?

    SaasAccount.joins(:user)
               .where(saas_id: risky_saas_ids)
               .where.not(users: { department: nil })
               .group("users.department")
               .count
               .sort_by { |_, v| -v }
  end
end
