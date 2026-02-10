class SaasAccountsController < ApplicationController
  before_action :set_saas_account, only: [:edit, :update, :destroy]

  def index
    @saas_accounts = SaasAccount.includes(:saas, :user)
    @saas_accounts = @saas_accounts.where(saas_id: params[:saas_id]) if params[:saas_id].present?
    @saas_accounts = @saas_accounts.where(user_id: params[:user_id]) if params[:user_id].present?
    @saas_accounts = @saas_accounts.where(status: params[:status]) if params[:status].present?
    @saas_accounts = @saas_accounts.order("saases.name, users.display_name")
                                   .page(params[:page]).per(25)
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

  private

  def set_saas_account
    @saas_account = SaasAccount.find(params[:id])
  end

  def saas_account_params
    params.require(:saas_account).permit(:saas_id, :user_id, :account_email, :role, :status, :last_login_at, :notes)
  end
end
