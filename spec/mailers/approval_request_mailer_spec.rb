require "rails_helper"

RSpec.describe ApprovalRequestMailer do
  let(:requester) { create(:user, display_name: "申請者", email: "requester@example.com") }
  let!(:admin1) { create(:user, :admin, display_name: "管理者1", email: "admin1@example.com") }
  let!(:manager1) { create(:user, :manager, display_name: "部長1", email: "manager1@example.com") }
  let(:saas) { create(:saas, name: "Notion", owner: create(:user, :manager, display_name: "SaaSオーナー", email: "owner@example.com")) }
  let(:approval_request) do
    create(:approval_request,
      requester: requester,
      saas: saas,
      saas_name: "Notion",
      request_type: "new_saas",
      reason: "プロジェクト管理に必要")
  end

  describe ".new_request" do
    let(:mail) { described_class.new_request(approval_request) }

    it "admin/managerに送信される" do
      expect(mail.to).to include(admin1.email)
      expect(mail.to).to include(manager1.email)
    end

    it "件名に対象SaaS名が含まれる" do
      expect(mail.subject).to eq("[SaaS管理] 承認依頼: Notion")
    end

    it "本文に申請情報が含まれる" do
      body = mail.body.encoded
      expect(body).to include("申請者")
      expect(body).to include("Notion")
      expect(body).to include("プロジェクト管理に必要")
    end
  end

  describe ".approved" do
    let(:approver) { admin1 }
    let(:mail) do
      approval_request.update!(status: :approved, approved_by: approver, approved_at: Time.current)
      described_class.approved(approval_request)
    end

    it "申請者に送信される" do
      expect(mail.to).to eq([ requester.email ])
    end

    it "SaaSオーナーがCCに入る" do
      expect(mail.cc).to include(saas.owner.email)
    end

    it "件名に承認結果が含まれる" do
      expect(mail.subject).to eq("[SaaS管理] 申請が承認されました: Notion")
    end
  end

  describe ".rejected" do
    let(:approver) { admin1 }
    let(:mail) do
      approval_request.update!(status: :rejected, approved_by: approver, rejection_reason: "予算超過のため")
      described_class.rejected(approval_request)
    end

    it "申請者に送信される" do
      expect(mail.to).to eq([ requester.email ])
    end

    it "SaaSオーナーがCCに入る" do
      expect(mail.cc).to include(saas.owner.email)
    end

    it "件名に却下結果が含まれる" do
      expect(mail.subject).to eq("[SaaS管理] 申請が却下されました: Notion")
    end

    it "本文に却下理由が含まれる" do
      expect(mail.body.encoded).to include("予算超過のため")
    end
  end

  describe ".approved（SaaSオーナー未設定の場合）" do
    let(:saas_no_owner) { create(:saas, name: "Slack", owner: nil) }
    let(:request_no_owner) { create(:approval_request, requester: requester, saas: saas_no_owner, saas_name: "Slack", reason: "連絡用") }
    let(:mail) do
      request_no_owner.update!(status: :approved, approved_by: admin1, approved_at: Time.current)
      described_class.approved(request_no_owner)
    end

    it "CCがnilまたは空" do
      expect(mail.cc || []).to be_empty
    end
  end
end
