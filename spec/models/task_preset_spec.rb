require "rails_helper"

RSpec.describe TaskPreset, type: :model do
  it "バリデーションが通る" do
    preset = build(:task_preset)
    expect(preset).to be_valid
  end

  it "name が必須" do
    preset = build(:task_preset, name: nil)
    expect(preset).not_to be_valid
  end

  it "task_type が必須" do
    preset = build(:task_preset, task_type: nil)
    expect(preset).not_to be_valid
  end

  it "task_type enumが正しく動作する" do
    preset = build(:task_preset, task_type: "onboarding")
    expect(preset).to be_onboarding
  end

  it "nested attributesでtask_preset_itemsを作成できる" do
    preset = TaskPreset.create!(
      name: "テスト",
      task_type: "offboarding",
      task_preset_items_attributes: [
        { action_type: "account_delete", description: "アカウント削除" }
      ]
    )
    expect(preset.task_preset_items.count).to eq(1)
  end
end
