require "rails_helper"

RSpec.describe TaskItem, type: :model do
  describe "バリデーション" do
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
  end

  describe "enum" do
    it "status enumが正しく動作する" do
      %w[pending completed].each do |status|
        item = build(:task_item, status: status)
        expect(item.status).to eq(status)
      end
    end

    it "無効なstatusでArgumentErrorが発生する" do
      expect { build(:task_item, status: "invalid") }.to raise_error(ArgumentError)
    end
  end

  describe "アソシエーション" do
    it "taskに属する" do
      item = create(:task_item)
      expect(item.task).to be_present
    end

    it "saasはオプション" do
      item = build(:task_item, saas: nil)
      expect(item).to be_valid
    end

    it "assigneeはオプション" do
      item = build(:task_item, assignee: nil)
      expect(item).to be_valid
    end

    it "assigneeにユーザーを設定できる" do
      user = create(:user)
      item = create(:task_item, assignee: user)
      expect(item.assignee).to eq(user)
    end
  end

  describe "#complete!" do
    it "完了にできる" do
      item = create(:task_item)
      item.complete!
      expect(item).to be_completed
      expect(item.completed_at).to be_present
    end

    it "completed_atに現在時刻が設定される" do
      item = create(:task_item)
      item.complete!
      expect(item.completed_at).to be_within(1.second).of(Time.current)
    end
  end
end
