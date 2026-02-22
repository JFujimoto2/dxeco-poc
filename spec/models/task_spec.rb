require "rails_helper"

RSpec.describe Task, type: :model do
  describe "バリデーション" do
    it "バリデーションが通る" do
      task = build(:task)
      expect(task).to be_valid
    end

    it "title が必須" do
      task = build(:task, title: nil)
      expect(task).not_to be_valid
    end

    it "task_type が必須" do
      task = build(:task, task_type: nil)
      expect(task).not_to be_valid
    end
  end

  describe "enum" do
    it "task_type enumが正しく動作する" do
      %w[onboarding offboarding transfer account_cleanup].each do |type|
        task = build(:task, task_type: type)
        expect(task).to be_valid
        expect(task.send("#{type}?")).to be true
      end
    end

    it "status enumが正しく動作する" do
      %w[open in_progress completed].each do |status|
        task = build(:task, status: status)
        expect(task.status).to eq(status)
      end
    end

    it "無効なtask_typeでArgumentErrorが発生する" do
      expect { build(:task, task_type: "invalid") }.to raise_error(ArgumentError)
    end

    it "無効なstatusでArgumentErrorが発生する" do
      expect { build(:task, status: "invalid") }.to raise_error(ArgumentError)
    end
  end

  describe "アソシエーション" do
    it "task_itemsを持てる" do
      task = create(:task)
      item = create(:task_item, task: task)
      expect(task.task_items).to include(item)
    end

    it "削除時にtask_itemsも削除される" do
      task = create(:task)
      create(:task_item, task: task)
      expect { task.destroy }.to change(TaskItem, :count).by(-1)
    end

    it "target_userはオプション" do
      task = build(:task, target_user: nil)
      expect(task).to be_valid
    end

    it "created_byは必須" do
      task = build(:task, created_by: nil)
      expect(task).not_to be_valid
    end
  end

  describe "#completion_rate" do
    it "完了率を計算できる" do
      task = create(:task)
      create(:task_item, task: task, status: "completed")
      create(:task_item, task: task, status: "pending")
      expect(task.completion_rate).to eq(50.0)
    end

    it "task_itemsが0件の場合0を返す" do
      task = create(:task)
      expect(task.completion_rate).to eq(0)
    end

    it "全件完了で100.0を返す" do
      task = create(:task)
      create(:task_item, task: task, status: "completed")
      create(:task_item, task: task, status: "completed")
      expect(task.completion_rate).to eq(100.0)
    end

    it "端数を丸める" do
      task = create(:task)
      3.times { create(:task_item, task: task, status: "completed") }
      7.times { create(:task_item, task: task, status: "pending") }
      expect(task.completion_rate).to eq(30.0)
    end
  end
end
