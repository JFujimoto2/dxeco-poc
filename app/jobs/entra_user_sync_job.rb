class EntraUserSyncJob < ApplicationJob
  queue_as :default

  def perform
    log = BatchExecutionLog.create!(job_name: self.class.name, status: "running", started_at: Time.current)
    stats = { processed_count: 0, created_count: 0, updated_count: 0, error_count: 0 }

    token = EntraClient.fetch_app_token
    entra_users = EntraClient.fetch_all_users(token)

    entra_users.each do |eu|
      email = eu["mail"] || eu["userPrincipalName"]
      user = User.find_by(entra_id_sub: eu["id"]) || User.find_by(email: email) || User.new
      user.entra_id_sub = eu["id"]
      user.assign_attributes(
        email: eu["mail"] || eu["userPrincipalName"],
        display_name: eu["displayName"],
        department: eu["department"],
        job_title: eu["jobTitle"],
        employee_id: eu["employeeId"],
        account_enabled: eu["accountEnabled"],
        last_password_change_at: eu["lastPasswordChangeDateTime"]
      )
      user.role ||= "viewer"
      stats[:created_count] += 1 if user.new_record?
      stats[:updated_count] += 1 if user.persisted? && user.changed?
      user.save!
      stats[:processed_count] += 1
    rescue => e
      Rails.logger.error("EntraUserSync: email=#{email} Error=#{e.message}")
      stats[:error_count] += 1
    end

    log.update!(status: "success", finished_at: Time.current, **stats)
    RetiredAccountDetectionJob.perform_later
  rescue => e
    log&.update!(status: "failure", finished_at: Time.current, error_messages: e.message)
    raise
  end
end
