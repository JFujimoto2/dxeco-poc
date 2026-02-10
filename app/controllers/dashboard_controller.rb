class DashboardController < ApplicationController
  def index
    @saas_count = Saas.count
    @user_count = User.count
    @account_count = SaasAccount.active.count
    @attention_count = Saas.cancelled.count + SaasAccount.where.not(status: "active").count
  end
end
