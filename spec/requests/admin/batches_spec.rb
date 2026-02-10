require "rails_helper"

RSpec.describe "Admin::Batches", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:viewer) { create(:user) }

  describe "GET /admin/batches" do
    it "adminはアクセスできる" do
      login_as(admin)
      get admin_batches_path
      expect(response).to have_http_status(:ok)
    end

    it "viewerはリダイレクトされる" do
      login_as(viewer)
      get admin_batches_path
      expect(response).to redirect_to(root_path)
    end

    it "実行履歴を表示" do
      login_as(admin)
      create(:batch_execution_log, job_name: "EntraUserSyncJob", status: "success")
      get admin_batches_path
      expect(response.body).to include("EntraUserSync")
    end
  end

  describe "POST /admin/batches/sync_entra_users" do
    it "ジョブをキューイングする" do
      login_as(admin)
      expect {
        post sync_entra_users_admin_batches_path
      }.to have_enqueued_job(EntraUserSyncJob)
      expect(response).to redirect_to(admin_batches_path)
    end
  end

  describe "POST /admin/batches/detect_retired_accounts" do
    it "ジョブをキューイングする" do
      login_as(admin)
      expect {
        post detect_retired_accounts_admin_batches_path
      }.to have_enqueued_job(RetiredAccountDetectionJob)
      expect(response).to redirect_to(admin_batches_path)
    end
  end
end
