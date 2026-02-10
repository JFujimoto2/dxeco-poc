require "rails_helper"

RSpec.describe Auditable, type: :model do
  let(:user) { create(:user, :admin) }

  before do
    Current.user = user
    Current.ip_address = "192.168.1.1"
  end

  after do
    Current.reset
  end

  describe "after_create" do
    it "作成時にaudit_logを記録する" do
      expect {
        create(:saas, name: "TestSaaS")
      }.to change(AuditLog, :count).by(1)

      log = AuditLog.last
      expect(log.action).to eq("create")
      expect(log.resource_type).to eq("Saas")
      expect(log.user).to eq(user)
      expect(log.ip_address).to eq("192.168.1.1")
    end
  end

  describe "after_update" do
    it "更新時にaudit_logを記録する" do
      saas = create(:saas, name: "OldName")
      AuditLog.delete_all

      expect {
        saas.update!(name: "NewName")
      }.to change(AuditLog, :count).by(1)

      log = AuditLog.last
      expect(log.action).to eq("update")
      expect(log.changes_data).to include("name" => [ "OldName", "NewName" ])
    end

    it "変更がない場合はログを記録しない" do
      saas = create(:saas, name: "Same")
      AuditLog.delete_all

      expect {
        saas.update!(name: "Same")
      }.not_to change(AuditLog, :count)
    end
  end

  describe "after_destroy" do
    it "削除時にaudit_logを記録する" do
      saas = create(:saas, name: "ToDelete")
      AuditLog.delete_all

      expect {
        saas.destroy!
      }.to change(AuditLog, :count).by(1)

      log = AuditLog.last
      expect(log.action).to eq("destroy")
      expect(log.resource_type).to eq("Saas")
    end
  end

  describe "Current.userが未設定の場合" do
    before { Current.user = nil }

    it "user_idがnilでログを記録する" do
      expect {
        create(:saas, name: "NoUser")
      }.to change(AuditLog, :count).by(1)

      expect(AuditLog.last.user).to be_nil
    end
  end
end
