require "rails_helper"

RSpec.describe "TaskItems", type: :request do
  let(:admin) { create(:user, :admin) }

  before { login_as(admin) }

  describe "PATCH /task_items/:id" do
    it "アイテムを完了にできる" do
      target = create(:user)
      task = create(:task, created_by: admin, target_user: target)
      item = create(:task_item, task: task)
      patch task_item_path(item), params: { complete: "true" }
      expect(item.reload).to be_completed
    end

    it "アイテムを未完了に戻せる" do
      target = create(:user)
      task = create(:task, created_by: admin, target_user: target, status: "in_progress")
      item = create(:task_item, task: task, status: "completed", completed_at: Time.current)
      patch task_item_path(item), params: { complete: "false" }
      expect(item.reload).to be_pending
    end

    it "全アイテム完了でタスクも完了になる" do
      target = create(:user)
      task = create(:task, created_by: admin, target_user: target, status: "in_progress")
      item = create(:task_item, task: task)
      patch task_item_path(item), params: { complete: "true" }
      expect(task.reload).to be_completed
    end
  end
end
