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
end
