require "rails_helper"

RSpec.describe TaskMailer do
  describe ".assignment_notification" do
    let(:admin) { create(:user, :admin, display_name: "管理者", email: "admin@example.com") }
    let!(:dept_manager) { create(:user, :manager, display_name: "部長", email: "manager@example.com", department: "営業部") }
    let(:assignee) { create(:user, display_name: "担当者A", email: "assignee@example.com", department: "営業部") }
    let(:target_user) { create(:user, display_name: "退職者", email: "retired@example.com", department: "営業部") }

    let(:task) { create(:task, title: "退職処理 - 退職者", created_by: admin, target_user: target_user, due_date: Date.new(2026, 3, 1)) }
    let!(:task_item) { create(:task_item, task: task, assignee: assignee, description: "Slackアカウント削除") }

    let(:mail) { described_class.assignment_notification(task) }

    it "アサイン先ユーザーに送信される" do
      expect(mail.to).to eq([ assignee.email ])
    end

    it "部署のmanagerとタスク作成者がCCに入る" do
      expect(mail.cc).to include(dept_manager.email)
      expect(mail.cc).to include(admin.email)
    end

    it "件名にプレフィックスとタスク名が含まれる" do
      expect(mail.subject).to eq("[SaaS管理] タスク対応のお願い: 退職処理 - 退職者")
    end

    it "本文にタスク情報が含まれる" do
      expect(mail.body.encoded).to include("退職処理 - 退職者")
      expect(mail.body.encoded).to include("Slackアカウント削除")
      expect(mail.body.encoded).to include("2026")
    end

    context "部署のmanagerが存在しない場合" do
      let(:assignee) { create(:user, display_name: "担当者A", email: "assignee@example.com", department: "技術部") }
      let(:target_user) { create(:user, display_name: "退職者", email: "retired@example.com", department: "技術部") }

      it "CCはタスク作成者のみ" do
        expect(mail.cc).to eq([ admin.email ])
      end
    end

    context "タスク作成者がアサイン先と同一人物の場合" do
      let(:task) { create(:task, title: "退職処理", created_by: assignee, target_user: target_user, due_date: Date.new(2026, 3, 1)) }

      it "CCにアサイン先が重複しない" do
        expect(mail.to).to eq([ assignee.email ])
        expect(mail.cc || []).not_to include(assignee.email)
      end
    end

    context "複数のアサイン先がある場合" do
      let(:assignee2) { create(:user, display_name: "担当者B", email: "assignee2@example.com", department: "営業部") }
      let!(:task_item2) { create(:task_item, task: task, assignee: assignee2, description: "Notionアカウント削除") }

      it "全アサイン先に送信される" do
        expect(mail.to).to contain_exactly(assignee.email, assignee2.email)
      end
    end
  end
end
