class SaasesController < ApplicationController
  before_action :set_saas, only: [ :show, :edit, :update, :destroy ]

  def index
    @saases = Saas.search_by_name(params[:q])
                  .filter_by_category(params[:category])
                  .filter_by_status(params[:status])
                  .order(:name)
                  .page(params[:page]).per(25)
    @categories = Saas.distinct.pluck(:category).compact.sort
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

  private

  def set_saas
    @saas = Saas.find(params[:id])
  end

  def saas_params
    params.require(:saas).permit(
      :name, :category, :url, :admin_url, :description, :owner_id, :status,
      saas_contract_attributes: [ :id, :plan_name, :price_cents, :billing_cycle, :started_on, :expires_on, :vendor, :notes ]
    )
  end
end
