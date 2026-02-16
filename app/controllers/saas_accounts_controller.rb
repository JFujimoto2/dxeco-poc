class SaasAccountsController < ApplicationController
  include CsvExportable

  before_action :set_saas_account, only: [ :edit, :update, :destroy ]
  before_action :require_admin_or_manager, only: [ :import ]

  def index
    @saas_accounts = SaasAccount.includes(:saas, :user)
                                .filter_by_saas(params[:saas_id])
                                .filter_by_user(params[:user_id])
                                .filter_by_status(params[:status])
                                .filter_by_department(params[:department])
                                .order("saases.name, users.display_name")
                                .page(params[:page]).per(25)
    @departments = User.distinct.pluck(:department).compact.sort
  end

  def new
    @saas_account = SaasAccount.new
  end

  def create
    @saas_account = SaasAccount.new(saas_account_params)
    if @saas_account.save
      redirect_to saas_accounts_path, notice: "アカウントを登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @saas_account.update(saas_account_params)
      redirect_to saas_accounts_path, notice: "アカウントを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @saas_account.destroy
    redirect_to saas_accounts_path, notice: "アカウントを削除しました", status: :see_other
  end

  def import
    unless params[:file].present?
      redirect_to saas_accounts_path, alert: "ファイルを選択してください"
      return
    end

    result = SaasAccountImportService.new(params[:file].tempfile.path).call
    if result[:error_count].zero?
      redirect_to saas_accounts_path, notice: "#{result[:success_count]}件のアカウントをインポートしました"
    else
      redirect_to saas_accounts_path, alert: "成功: #{result[:success_count]}件, エラー: #{result[:error_count]}件 (#{result[:errors].first(3).join(' / ')})"
    end
  end

  def export
    accounts = SaasAccount.includes(:saas, :user)
                          .filter_by_saas(params[:saas_id])
                          .filter_by_user(params[:user_id])
                          .filter_by_status(params[:status])
                          .filter_by_department(params[:department])
                          .order("saases.name, users.display_name")
    rows = accounts.map do |a|
      [ a.saas.name, a.user.display_name, a.user.department,
       a.account_email, a.role, a.status, a.last_login_at&.strftime("%Y/%m/%d %H:%M") ]
    end
    send_csv(
      filename: "saas_accounts_export",
      headers: %w[SaaS名 メンバー名 部署 アカウントメール ロール ステータス 最終ログイン],
      rows: rows
    )
  end

  def download_template
    csv_data = "\uFEFF" + CSV.generate { |csv|
      csv << %w[SaaS名 ユーザーメール アカウントメール ロール ステータス]
      csv << [ "Slack", "user@example.com", "user@example.com", "member", "active" ]
    }
    send_data csv_data, filename: "saas_account_template.csv", type: "text/csv; charset=utf-8"
  end

  private

  def set_saas_account
    @saas_account = SaasAccount.find(params[:id])
  end

  def saas_account_params
    permitted = params.require(:saas_account).permit(:saas_id, :user_id, :account_email, :status, :last_login_at, :notes)
    permitted[:role] = params[:saas_account][:role] if current_user&.admin? && params[:saas_account][:role].present?
    permitted
  end
end
