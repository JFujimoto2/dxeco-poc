class EntraAccountSyncJob < ApplicationJob
  queue_as :default

  def perform
    log = BatchExecutionLog.create!(job_name: self.class.name, status: "running", started_at: Time.current)
    stats = { processed_count: 0, created_count: 0, updated_count: 0, error_count: 0 }
    matched_saas_count = 0

    token = EntraClient.fetch_app_token
    service_principals = EntraClient.fetch_service_principals(token)

    service_principals.each do |sp|
      saas = find_matching_saas(sp)
      next unless saas

      matched_saas_count += 1
      saas.update!(entra_app_id: sp["id"]) if saas.entra_app_id.blank?

      assignments = EntraClient.fetch_app_role_assignments(token, sp["id"])
      assigned_user_ids = []

      assignments.each do |assignment|
        user = User.find_by(entra_id_sub: assignment["principalId"])
        next unless user

        assigned_user_ids << user.id
        account = SaasAccount.find_or_initialize_by(saas: saas, user: user)
        if account.new_record?
          account.account_email = user.email
          account.status = "active"
          account.save!
          stats[:created_count] += 1
        end
        stats[:processed_count] += 1
      rescue => e
        stats[:error_count] += 1
      end

      # 割り当て解除されたアカウントを suspended に
      saas.saas_accounts.active.where.not(user_id: assigned_user_ids).find_each do |account|
        account.update!(status: "suspended")
        stats[:updated_count] += 1
      end
    end

    log.update!(status: "success", finished_at: Time.current, **stats)
    send_notification(stats, service_principals.size, matched_saas_count)
  rescue => e
    log&.update!(status: "failure", finished_at: Time.current, error_messages: e.message)
    raise
  end

  private

  def find_matching_saas(sp)
    Saas.find_by(entra_app_id: sp["id"]) || Saas.find_by("LOWER(name) = ?", sp["displayName"]&.downcase)
  end

  def send_notification(stats, total_apps, matched_count)
    TeamsNotifier.notify(
      title: "SaaSアカウント同期完了",
      body: "検出アプリ: #{total_apps}件 / マッチSaaS: #{matched_count}件\n" \
            "新規アカウント: #{stats[:created_count]}件 / 停止: #{stats[:updated_count]}件 / エラー: #{stats[:error_count]}件",
      level: stats[:error_count] > 0 ? "warning" : "good"
    )
  end
end
