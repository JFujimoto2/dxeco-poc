require "rails_helper"

RSpec.describe TaskItem, type: :model do
  it "バリデーションが通る" do
    item = build(:task_item)
    expect(item).to be_valid
  end

  it "action_type が必須" do
    item = build(:task_item, action_type: nil)
    expect(item).not_to be_valid
  end

  it "description が必須" do
    item = build(:task_item, description: nil)
    expect(item).not_to be_valid
  end

  it "complete!で完了にできる" do
    item = create(:task_item)
    item.complete!
    expect(item).to be_completed
    expect(item.completed_at).to be_present
  end
end
