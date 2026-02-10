require "rails_helper"

RSpec.describe BatchExecutionLog, type: :model do
  it "バリデーションが通る" do
    log = build(:batch_execution_log)
    expect(log).to be_valid
  end

  it "job_name が必須" do
    log = build(:batch_execution_log, job_name: nil)
    expect(log).not_to be_valid
  end

  it "ステータスenumが正しく動作する" do
    log = create(:batch_execution_log, status: "success")
    expect(log).to be_success
  end

  it "recentスコープが新しい順に返す" do
    old = create(:batch_execution_log, created_at: 1.day.ago)
    recent = create(:batch_execution_log, created_at: Time.current)
    expect(BatchExecutionLog.recent.first).to eq(recent)
  end
end
