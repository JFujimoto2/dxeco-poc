require "rails_helper"

RSpec.describe User, type: :model do
  describe "バリデーション" do
    it "正しい属性で有効" do
      user = build(:user)
      expect(user).to be_valid
    end

    it "entra_id_sub が必須" do
      user = build(:user, entra_id_sub: nil)
      expect(user).not_to be_valid
    end

    it "entra_id_sub が一意" do
      create(:user, entra_id_sub: "same-id")
      user = build(:user, entra_id_sub: "same-id")
      expect(user).not_to be_valid
    end

    it "email が必須" do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
    end

    it "role が必須" do
      user = build(:user, role: nil)
      expect(user).not_to be_valid
    end
  end

  describe "enum" do
    it "viewer ロール" do
      user = build(:user, role: "viewer")
      expect(user).to be_viewer
    end

    it "manager ロール" do
      user = build(:user, :manager)
      expect(user).to be_manager
    end

    it "admin ロール" do
      user = build(:user, :admin)
      expect(user).to be_admin
    end
  end

  describe "パスワード期限スコープ" do
    before do
      @expired_user = create(:user, last_password_change_at: 100.days.ago, account_enabled: true)
      @expiring_user = create(:user, last_password_change_at: 80.days.ago, account_enabled: true)
      @safe_user = create(:user, last_password_change_at: 10.days.ago, account_enabled: true)
      @disabled_user = create(:user, last_password_change_at: 100.days.ago, account_enabled: false)
      @no_password_user = create(:user, last_password_change_at: nil, account_enabled: true)
    end

    describe ".password_expired" do
      it "90日以上パスワード変更していない有効ユーザーを返す" do
        result = User.password_expired
        expect(result).to include(@expired_user)
        expect(result).not_to include(@expiring_user, @safe_user, @disabled_user, @no_password_user)
      end
    end

    describe ".password_expiring_soon" do
      it "14日以内にパスワードが期限切れになる有効ユーザーを返す" do
        result = User.password_expiring_soon
        expect(result).to include(@expiring_user)
        expect(result).not_to include(@expired_user, @safe_user, @disabled_user, @no_password_user)
      end

      it "カスタム警告日数を指定できる" do
        result = User.password_expiring_soon(30)
        expect(result).to include(@expiring_user)
      end
    end
  end
end
