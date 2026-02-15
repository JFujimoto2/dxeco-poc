class TaskMailer < ApplicationMailer
  def assignment_notification(task)
    @task = task
    @task_items = task.task_items.includes(:assignee, :saas)

    to_emails = @task_items.filter_map { |item| item.assignee&.email }.uniq
    return if to_emails.empty?

    cc_emails = build_cc(task, to_emails)

    mail(
      to: to_emails,
      cc: cc_emails.presence,
      subject: "[SaaS管理] タスク対応のお願い: #{task.title}"
    )
  end

  private

  def build_cc(task, to_emails)
    cc = []

    # 対象ユーザーの部署のmanager
    departments = task.task_items.includes(:assignee).filter_map { |item| item.assignee&.department }.uniq
    if departments.any?
      managers = User.manager.where(department: departments)
      cc.concat(managers.pluck(:email))
    end

    # タスク作成者
    cc << task.created_by.email

    (cc.uniq - to_emails)
  end
end
