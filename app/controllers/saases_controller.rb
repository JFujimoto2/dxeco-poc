class SaasesController < ApplicationController
  include CsvExportable

  before_action :set_saas, only: [ :show, :edit, :update, :destroy ]
  before_action :require_admin_or_manager, only: [ :import ]

  def index
    @saases = Saas.search_by_name(params[:q])
                  .filter_by_category(params[:category])
                  .filter_by_status(params[:status])
                  .filter_by_auth_method(params[:auth_method])
                  .filter_by_data_location(params[:data_location])
                  .filter_by_department(params[:department])
                  .includes(:saas_accounts, :owner)
                  .order(:name)
                  .page(params[:page]).per(25)
    @categories = Saas.distinct.pluck(:category).compact.sort
    @departments = User.distinct.pluck(:department).compact.sort
  end

  def show
    @saas_accounts = @saas.saas_accounts.includes(:user).order("users.display_name")
  end

  def new
    @saas = Saas.new
    @saas.build_saas_contract
  end

  def create
    @saas = Saas.new(saas_params)
    if @saas.save
      redirect_to @saas, notice: "SaaSを登録しました"
    else
      @saas.build_saas_contract unless @saas.saas_contract
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @saas.build_saas_contract unless @saas.saas_contract
  end

  def update
    if @saas.update(saas_params)
      redirect_to @saas, notice: "SaaSを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @saas.destroy
    redirect_to saases_path, notice: "SaaSを削除しました", status: :see_other
  end

  def import
    unless params[:file].present?
      redirect_to saases_path, alert: "ファイルを選択してください"
      return
    end

    result = SaasImportService.new(params[:file].tempfile.path).call
    if result[:error_count].zero?
      redirect_to saases_path, notice: "#{result[:success_count]}件のSaaSをインポートしました"
    else
      redirect_to saases_path, alert: "成功: #{result[:success_count]}件, エラー: #{result[:error_count]}件 (#{result[:errors].first(3).join(' / ')})"
    end
  end

  def export
    saases = Saas.search_by_name(params[:q])
                 .filter_by_category(params[:category])
                 .filter_by_status(params[:status])
                 .filter_by_auth_method(params[:auth_method])
                 .filter_by_data_location(params[:data_location])
                 .filter_by_department(params[:department])
                 .includes(:saas_contract, :owner)
                 .order(:name)
    rows = saases.map do |saas|
      c = saas.saas_contract
      [ saas.name, saas.category, saas.status, saas.url, saas.owner&.display_name,
       c&.plan_name, c&.price_cents, c&.billing_cycle, c&.expires_on,
       saas.handles_personal_data ? "あり" : "なし", saas.auth_method || "", saas.data_location || "" ]
    end
    send_csv(
      filename: "saas_export",
      headers: %w[SaaS名 カテゴリ ステータス URL 担当者 プラン 月額 請求サイクル 契約期限 個人情報取扱い 認証方式 データ保存先],
      rows: rows
    )
  end

  def download_template
    csv_data = "\uFEFF" + CSV.generate { |csv|
      csv << %w[SaaS名 カテゴリ ステータス URL 管理画面URL 説明 個人情報取扱い 認証方式 データ保存先]
      csv << [ "サンプルSaaS", "一般", "active", "https://example.com", "", "サービスの説明", "なし", "SSO", "国内" ]
    }
    send_data csv_data, filename: "saas_template.csv", type: "text/csv; charset=utf-8"
  end

  private

  def set_saas
    @saas = Saas.find(params[:id])
  end

  def saas_params
    params.require(:saas).permit(
      :name, :category, :url, :admin_url, :description, :owner_id, :status, :entra_app_id,
      :handles_personal_data, :auth_method, :data_location,
      saas_contract_attributes: [ :id, :plan_name, :price_cents, :billing_cycle, :started_on, :expires_on, :vendor, :notes ]
    )
  end
end
