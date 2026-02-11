class ApprovalRequestsController < ApplicationController
  def index
    if current_user.admin? || current_user.manager?
      @pending_requests = ApprovalRequest.pending.includes(:requester, :saas).order(created_at: :desc)
      @all_requests = ApprovalRequest.includes(:requester, :saas).order(created_at: :desc).page(params[:page])
    else
      @pending_requests = []
      @all_requests = ApprovalRequest.where(requester: current_user).order(created_at: :desc).page(params[:page])
    end
  end

  def new
    @approval_request = ApprovalRequest.new
    @saases = Saas.where(status: "active").order(:name)
    @approvers = User.where(role: [ :admin, :manager ]).order(:display_name)
    default_approver = @approvers.find_by(department: "情報システム部", role: :manager)
    @approval_request.approver_id = default_approver&.id
  end

  def create
    @approval_request = ApprovalRequest.new(request_params)
    @approval_request.requester = current_user
    if @approval_request.save
      TeamsNotifier.notify(
        title: "SaaS利用申請",
        body: "#{current_user.display_name}さんから申請があります。\n種別: #{@approval_request.request_type}\n対象: #{@approval_request.target_saas_name}\n理由: #{@approval_request.reason}",
        link: "#{ENV.fetch('APP_URL', 'http://localhost:3000')}/approval_requests/#{@approval_request.id}"
      )
      ApprovalRequestMailer.new_request(@approval_request).deliver_later
      redirect_to approval_requests_path, notice: "申請を送信しました"
    else
      @saases = Saas.where(status: "active").order(:name)
      @approvers = User.where(role: [ :admin, :manager ]).order(:display_name)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @approval_request = ApprovalRequest.find(params[:id])
  end

  def approve
    request = ApprovalRequest.find(params[:id])
    unless current_user.admin? || current_user.manager?
      redirect_to approval_requests_path, alert: "承認権限がありません"
      return
    end
    request.update!(
      status: :approved,
      approved_by: current_user,
      approved_at: Time.current
    )
    TeamsNotifier.notify(
      title: "申請が承認されました",
      body: "「#{request.target_saas_name}」の利用申請が#{current_user.display_name}によって承認されました。",
      link: "#{ENV.fetch('APP_URL', 'http://localhost:3000')}/approval_requests/#{request.id}"
    )
    ApprovalRequestMailer.approved(request).deliver_later
    redirect_to approval_request_path(request), notice: "承認しました"
  end

  def reject
    request = ApprovalRequest.find(params[:id])
    unless current_user.admin? || current_user.manager?
      redirect_to approval_requests_path, alert: "承認権限がありません"
      return
    end
    request.update!(
      status: :rejected,
      approved_by: current_user,
      approved_at: Time.current,
      rejection_reason: params[:rejection_reason]
    )
    TeamsNotifier.notify(
      title: "申請が却下されました",
      body: "「#{request.target_saas_name}」の利用申請が却下されました。\n理由: #{request.rejection_reason}",
      link: "#{ENV.fetch('APP_URL', 'http://localhost:3000')}/approval_requests/#{request.id}"
    )
    ApprovalRequestMailer.rejected(request).deliver_later
    redirect_to approval_request_path(request), notice: "却下しました"
  end

  private

  def request_params
    params.require(:approval_request).permit(:request_type, :saas_id, :saas_name, :reason, :estimated_cost, :user_count, :approver_id)
  end
end
