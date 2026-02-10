require "rails_helper"

RSpec.describe ApprovalRequest, type: :model do
  it "バリデーションが通る" do
    request = build(:approval_request)
    expect(request).to be_valid
  end

  it "reason が必須" do
    request = build(:approval_request, reason: nil)
    expect(request).not_to be_valid
  end

  it "ステータスenumが正しく動作する" do
    request = build(:approval_request, status: "approved")
    expect(request).to be_approved
  end

  it "request_type enumが正しく動作する" do
    request = build(:approval_request, request_type: "add_account")
    expect(request).to be_add_account
  end

  it "target_saas_nameが既存SaaSの場合" do
    saas = create(:saas, name: "Slack")
    request = build(:approval_request, saas: saas, saas_name: nil)
    expect(request.target_saas_name).to eq("Slack")
  end

  it "target_saas_nameが新規SaaSの場合" do
    request = build(:approval_request, saas: nil, saas_name: "Figma")
    expect(request.target_saas_name).to eq("Figma")
  end
end
