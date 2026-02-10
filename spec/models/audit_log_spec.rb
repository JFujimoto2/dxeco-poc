require "rails_helper"

RSpec.describe AuditLog, type: :model do
  describe "バリデーション" do
    it "有効なファクトリ" do
      expect(build(:audit_log)).to be_valid
    end

    it "actionは必須" do
      expect(build(:audit_log, action: nil)).not_to be_valid
    end

    it "resource_typeは必須" do
      expect(build(:audit_log, resource_type: nil)).not_to be_valid
    end

    it "resource_idは必須" do
      expect(build(:audit_log, resource_id: nil)).not_to be_valid
    end

    it "userはオプション（バッチ実行時はnull）" do
      expect(build(:audit_log, user: nil)).to be_valid
    end
  end

  describe "スコープ" do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }

    before { AuditLog.delete_all }

    it "recent: 新しい順に返す" do
      old = create(:audit_log, user: user1, created_at: 2.days.ago)
      recent = create(:audit_log, user: user2, created_at: 1.hour.ago)
      expect(AuditLog.recent.to_a).to eq([ recent, old ])
    end

    it "by_resource_type: リソース種別で絞り込み" do
      saas_log = create(:audit_log, user: user1, resource_type: "Saas")
      create(:audit_log, user: user2, resource_type: "User")
      expect(AuditLog.by_resource_type("Saas").to_a).to eq([ saas_log ])
    end

    it "by_user: ユーザーで絞り込み" do
      user_log = create(:audit_log, user: user1)
      create(:audit_log, user: user2)
      expect(AuditLog.by_user(user1.id).to_a).to eq([ user_log ])
    end

    it "by_date_range: 日付範囲で絞り込み" do
      create(:audit_log, user: user1, created_at: 10.days.ago)
      recent = create(:audit_log, user: user2, created_at: 1.day.ago)
      expect(AuditLog.by_date_range(3.days.ago, Time.current).to_a).to eq([ recent ])
    end
  end

  describe "アソシエーション" do
    it "userに属する" do
      user = create(:user)
      log = create(:audit_log, user: user)
      expect(log.user).to eq(user)
    end
  end
end
