class UsersController < ApplicationController
  before_action :set_user, only: [ :show, :edit, :update ]
  before_action :require_admin, only: [ :edit, :update ]

  def index
    @users = User.search_by_name(params[:q])
                 .filter_by_department(params[:department])
                 .order(:display_name)
                 .page(params[:page]).per(25)
    @departments = User.distinct.pluck(:department).compact.sort
  end

  def show
    @saas_accounts = @user.saas_accounts.includes(:saas).order("saases.name")
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to @user, notice: "メンバー情報を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    permitted = params.require(:user).permit(:display_name, :department, :job_title)
    permitted[:role] = params[:user][:role] if current_user&.admin? && params[:user][:role].present?
    permitted
  end
end
