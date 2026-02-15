class ContractRenewalAlertJob < ApplicationJob
  queue_as :default

  def perform
    log = BatchExecutionLog.create!(job_name: self.class.name, status: "running", started_at: Time.current)

    expiring_30 = SaasContract.expiring_soon(30).includes(:saas)
    expiring_7 = SaasContract.expiring_soon(7).includes(:saas)
    alert_contracts = expiring_30.to_a

    log.update!(
      status: "success",
      finished_at: Time.current,
      processed_count: SaasContract.count,
      created_count: alert_contracts.size
    )

    if alert_contracts.any?
      body = ""
      if expiring_7.any?
        body += "**7日以内に期限切れ:**\n"
        body += expiring_7.map { |c| "- #{c.saas.name}（#{c.plan_name}）: #{c.expires_on.strftime('%Y/%m/%d')}" }.join("\n")
        body += "\n\n"
      end

      remaining_30 = alert_contracts.reject { |c| c.expires_on <= 7.days.from_now.to_date }
      if remaining_30.any?
        body += "**30日以内に期限切れ:**\n"
        body += remaining_30.map { |c| "- #{c.saas.name}（#{c.plan_name}）: #{c.expires_on.strftime('%Y/%m/%d')}" }.join("\n")
      end

      TeamsNotifier.notify(
        title: "契約更新アラート: #{alert_contracts.size}件",
        body: body,
        level: :warning,
        link: "#{ENV.fetch('APP_URL', 'http://localhost:3000')}/"
      )
    end
  rescue => e
    log&.update!(status: "failure", finished_at: Time.current, error_messages: e.message)
    raise
  end
end
