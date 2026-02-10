require "rails_helper"

RSpec.describe Task, type: :model do
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

  it "ステータスenumが正しく動作する" do
    task = build(:task, status: "in_progress")
    expect(task).to be_in_progress
  end

  it "completion_rateを計算できる" do
    task = create(:task)
    create(:task_item, task: task, status: "completed")
    create(:task_item, task: task, status: "pending")
    expect(task.completion_rate).to eq(50.0)
  end

  it "task_itemsが0件の場合completion_rateが0" do
    task = create(:task)
    expect(task.completion_rate).to eq(0)
  end
end
