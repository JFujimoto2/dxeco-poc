module Admin
  class AuditLogsController < ApplicationController
    before_action :require_admin

    def index
      @audit_logs = AuditLog.includes(:user)
                            .by_resource_type(params[:resource_type])
                            .by_user(params[:user_id])
                            .by_date_range(params[:date_from], params[:date_to])
                            .recent
                            .page(params[:page]).per(30)
      @resource_types = AuditLog.distinct.pluck(:resource_type).sort
      @users = User.order(:display_name)
    end

    def show
      @audit_log = AuditLog.find(params[:id])
    end
  end
end
