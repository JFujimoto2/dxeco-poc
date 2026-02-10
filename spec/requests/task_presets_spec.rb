require "rails_helper"

RSpec.describe "TaskPresets", type: :request do
  let(:admin) { create(:user, :admin) }

  before { login_as(admin) }

  describe "GET /task_presets" do
    it "一覧を表示" do
      create(:task_preset, name: "退職処理")
      get task_presets_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("退職処理")
    end
  end

  describe "POST /task_presets" do
    it "プリセットを作成" do
      expect {
        post task_presets_path, params: {
          task_preset: {
            name: "テスト", task_type: "offboarding",
            task_preset_items_attributes: [
              { action_type: "account_delete", description: "アカウント削除" }
            ]
          }
        }
      }.to change(TaskPreset, :count).by(1)
    end
  end

  describe "PATCH /task_presets/:id" do
    it "プリセットを更新" do
      preset = create(:task_preset, name: "旧名")
      patch task_preset_path(preset), params: { task_preset: { name: "新名" } }
      expect(preset.reload.name).to eq("新名")
    end
  end

  describe "DELETE /task_presets/:id" do
    it "プリセットを削除" do
      preset = create(:task_preset)
      expect {
        delete task_preset_path(preset)
      }.to change(TaskPreset, :count).by(-1)
    end
  end
end
