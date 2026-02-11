class ApprovalRequestMailer < ApplicationMailer
  def new_request(approval_request)
    @request = approval_request
    to_emails = User.where(role: [ :admin, :manager ]).pluck(:email)
    return if to_emails.empty?

    mail(
      to: to_emails,
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
