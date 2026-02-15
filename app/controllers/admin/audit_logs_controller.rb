module Admin
  class AuditLogsController < ApplicationController
    include CsvExportable

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

    def export
      logs = AuditLog.includes(:user)
                     .by_resource_type(params[:resource_type])
                     .by_user(params[:user_id])
                     .by_date_range(params[:date_from], params[:date_to])
                     .recent
      rows = logs.map do |log|
        [ log.created_at.strftime("%Y/%m/%d %H:%M:%S"),
         log.action, log.resource_type, log.resource_id,
         log.user&.display_name || "システム", log.ip_address ]
      end
      send_csv(
        filename: "audit_logs_export",
        headers: %w[日時 操作 リソース種別 リソースID ユーザー IPアドレス],
        rows: rows
      )
    end
  end
end
