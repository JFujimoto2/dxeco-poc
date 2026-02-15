require "rails_helper"

RSpec.describe "ApprovalRequests", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:viewer) { create(:user) }

  describe "GET /approval_requests" do
    it "adminは全申請を表示" do
      login_as(admin)
      create(:approval_request, requester: viewer, saas_name: "Figma")
      get approval_requests_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Figma")
    end

    it "viewerは自分の申請のみ表示" do
      login_as(viewer)
      create(:approval_request, requester: viewer, saas_name: "MyApp")
      create(:approval_request, requester: admin, saas_name: "OtherApp")
      get approval_requests_path
      expect(response.body).to include("MyApp")
      expect(response.body).not_to include("OtherApp")
    end
  end

  describe "POST /approval_requests" do
    it "申請を作成" do
      login_as(viewer)
      expect {
        post approval_requests_path, params: {
          approval_request: {
            request_type: "new_saas", saas_name: "Figma",
            reason: "デザインツールが必要", estimated_cost: 5000, user_count: 3
          }
        }
      }.to change(ApprovalRequest, :count).by(1)
    end

    it "承認者を指定して申請を作成" do
      login_as(viewer)
      manager = create(:user, :manager)
      post approval_requests_path, params: {
        approval_request: {
          request_type: "new_saas", saas_name: "Figma",
          reason: "デザインツールが必要", approver_id: manager.id
        }
      }
      expect(ApprovalRequest.last.approver).to eq(manager)
    end
  end

  describe "POST /approval_requests/:id/approve" do
    it "adminが承認できる" do
      login_as(admin)
      request = create(:approval_request, requester: viewer)
      post approve_approval_request_path(request)
      expect(request.reload).to be_approved
      expect(request.approved_by).to eq(admin)
    end

    it "viewerは承認できない" do
      login_as(viewer)
      request = create(:approval_request, requester: create(:user))
      post approve_approval_request_path(request)
      expect(response).to redirect_to(approval_requests_path)
      expect(request.reload).to be_pending
    end
  end

  describe "POST /approval_requests/:id/reject" do
    it "adminが却下できる" do
      login_as(admin)
      request = create(:approval_request, requester: viewer)
      post reject_approval_request_path(request), params: { rejection_reason: "コスト超過" }
      expect(request.reload).to be_rejected
      expect(request.rejection_reason).to eq("コスト超過")
    end

    it "viewerは却下できない" do
      login_as(viewer)
      request = create(:approval_request, requester: create(:user))
      post reject_approval_request_path(request)
      expect(response).to redirect_to(approval_requests_path)
      expect(request.reload).to be_pending
    end
  end

  describe "GET /approval_requests/new" do
    it "新規申請画面を表示" do
      login_as(viewer)
      get new_approval_request_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /approval_requests/:id" do
    it "adminは任意の申請詳細を表示できる" do
      login_as(admin)
      request = create(:approval_request, requester: viewer, saas_name: "DetailApp")
      get approval_request_path(request)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("DetailApp")
    end

    it "viewerは自分の申請を表示できる" do
      login_as(viewer)
      request = create(:approval_request, requester: viewer, saas_name: "MyRequest")
      get approval_request_path(request)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("MyRequest")
    end

    it "viewerは他人の申請を表示できない" do
      login_as(viewer)
      other = create(:user)
      request = create(:approval_request, requester: other, saas_name: "OtherRequest")
      get approval_request_path(request)
      expect(response).to redirect_to(approval_requests_path)
    end
  end

  describe "POST /approval_requests (managerの承認)" do
    it "managerが承認できる" do
      manager = create(:user, :manager)
      login_as(manager)
      request = create(:approval_request, requester: viewer)
      post approve_approval_request_path(request)
      expect(request.reload).to be_approved
      expect(request.approved_by).to eq(manager)
    end
  end
end
