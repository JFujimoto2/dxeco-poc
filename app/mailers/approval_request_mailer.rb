class ApprovalRequestMailer < ApplicationMailer
  def new_request(approval_request)
    @request = approval_request

    if @request.approver.present?
      to_emails = [ @request.approver.email ]
      exclude_ids = [ @request.approver_id, @request.requester_id ]
      cc_emails = User.where(role: [ :admin, :manager ]).where.not(id: exclude_ids).pluck(:email)
    else
      to_emails = User.where(role: [ :admin, :manager ]).pluck(:email)
      cc_emails = nil
    end
    return if to_emails.empty?

    mail(
      to: to_emails,
      cc: cc_emails.presence,
      subject: "[SaaS管理] 承認依頼: #{@request.target_saas_name}"
    )
  end

  def approved(approval_request)
    @request = approval_request
    cc_emails = build_saas_owner_cc(approval_request)

    mail(
      to: @request.requester.email,
      cc: cc_emails.presence,
      subject: "[SaaS管理] 申請が承認されました: #{@request.target_saas_name}"
    )
  end

  def rejected(approval_request)
    @request = approval_request
    cc_emails = build_saas_owner_cc(approval_request)

    mail(
      to: @request.requester.email,
      cc: cc_emails.presence,
      subject: "[SaaS管理] 申請が却下されました: #{@request.target_saas_name}"
    )
  end

  private

  def build_saas_owner_cc(approval_request)
    owner = approval_request.saas&.owner
    return [] unless owner
    [ owner.email ] - [ approval_request.requester.email ]
  end
end
