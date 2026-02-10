require "rails_helper"

RSpec.describe "Admin::AuditLogs", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:viewer) { create(:user) }

  describe "GET /admin/audit_logs" do
    it "adminは一覧を表示できる" do
      login_as(admin)
      create(:audit_log, action: "create", resource_type: "Saas")
      get admin_audit_logs_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("操作ログ")
    end

    it "viewerはアクセスできない" do
      login_as(viewer)
      get admin_audit_logs_path
      expect(response).to redirect_to(root_path)
    end

    it "リソース種別でフィルタできる" do
      login_as(admin)
      create(:audit_log, resource_type: "Saas", action: "create")
      create(:audit_log, resource_type: "User", action: "update")
      get admin_audit_logs_path, params: { resource_type: "Saas" }
      expect(response).to have_http_status(:ok)
    end

    it "ユーザーでフィルタできる" do
      login_as(admin)
      other_user = create(:user)
      create(:audit_log, user: other_user, action: "create")
      get admin_audit_logs_path, params: { user_id: other_user.id }
      expect(response).to have_http_status(:ok)
    end

    it "日付範囲でフィルタできる" do
      login_as(admin)
      create(:audit_log, created_at: 1.day.ago)
      get admin_audit_logs_path, params: { date_from: 2.days.ago.to_date, date_to: Date.today }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/audit_logs/:id" do
    it "adminは詳細を表示できる" do
      login_as(admin)
      log = create(:audit_log, changes_data: { "name" => %w[OldName NewName] })
      get admin_audit_log_path(log)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("OldName")
      expect(response.body).to include("NewName")
    end

    it "viewerはアクセスできない" do
      login_as(viewer)
      log = create(:audit_log)
      get admin_audit_log_path(log)
      expect(response).to redirect_to(root_path)
    end
  end
end
