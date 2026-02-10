module Auditable
  extend ActiveSupport::Concern

  included do
    after_create :log_create
    after_update :log_update
    after_destroy :log_destroy
  end

  private

  def log_create
    write_audit_log("create")
  end

  def log_update
    return if saved_changes.except("updated_at", "created_at").empty?

    write_audit_log("update", saved_changes.except("updated_at", "created_at"))
  end

  def log_destroy
    write_audit_log("destroy")
  end

  def write_audit_log(action, changes = {})
    AuditLog.create!(
      user: Current.user,
      action: action,
      resource_type: self.class.name,
      resource_id: id,
      changes_data: changes,
      ip_address: Current.ip_address
    )
  end
end
