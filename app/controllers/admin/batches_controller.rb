class Admin::BatchesController < ApplicationController
  before_action :require_admin

  def index
    @logs = BatchExecutionLog.recent.page(params[:page]).per(20)
  end

  def sync_entra_users
    EntraUserSyncJob.perform_later
    redirect_to admin_batches_path, notice: "Entra IDユーザー同期を開始しました"
  end

  def detect_retired_accounts
    RetiredAccountDetectionJob.perform_later
    redirect_to admin_batches_path, notice: "退職者アカウント検出を開始しました"
  end

  def check_contract_renewals
    ContractRenewalAlertJob.perform_later
    redirect_to admin_batches_path, notice: "契約更新チェックを開始しました"
  end

  def sync_entra_accounts
    EntraAccountSyncJob.perform_later
    redirect_to admin_batches_path, notice: "SaaSアカウント同期を開始しました"
  end
end
