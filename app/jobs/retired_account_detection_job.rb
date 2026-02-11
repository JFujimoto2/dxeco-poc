class RetiredAccountDetectionJob < ApplicationJob
  queue_as :default

  def perform
    log = BatchExecutionLog.create!(job_name: self.class.name, status: "running", started_at: Time.current)

    retired_users = User.where(account_enabled: false)
    results = []

    retired_users.find_each do |user|
      remaining = user.saas_accounts.where(status: "active").includes(:saas)
      if remaining.any?
        results << {
          user_name: user.display_name,
          user_email: user.email,
          accounts: remaining.map { |a| { saas_name: a.saas.name, email: a.account_email } }
        }
      end
    end

    log.update!(
      status: "success",
      finished_at: Time.current,
      processed_count: retired_users.count,
      created_count: results.size,
      error_messages: results.any? ? results.to_json : nil
    )

    if results.any?
      TeamsNotifier.notify(
        title: "退職者アカウント検出: #{results.size}名",
        body: results.map { |r|
          "#{r[:user_name]} (#{r[:user_email]})\n" +
          r[:accounts].map { |a| "  - #{a[:saas_name]}: #{a[:email]}" }.join("\n")
        }.join("\n\n"),
        level: :warning,
        link: "#{ENV.fetch('APP_URL', 'http://localhost:3000')}/admin/batches"
      )
    end
  rescue => e
    log&.update!(status: "failure", finished_at: Time.current, error_messages: e.message)
    raise
  end
end
