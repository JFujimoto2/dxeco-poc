class ApprovalRequestsController < ApplicationController
  before_action :set_approval_request, only: [ :show, :approve, :reject ]
  before_action :authorize_show, only: [ :show ]
  before_action :require_admin_or_manager, only: [ :approve, :reject ]

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
  end

  def approve
    @approval_request.update!(
      status: :approved,
      approved_by: current_user,
      approved_at: Time.current
    )
    TeamsNotifier.notify(
      title: "申請が承認されました",
      body: "「#{@approval_request.target_saas_name}」の利用申請が#{current_user.display_name}によって承認されました。",
      link: "#{ENV.fetch('APP_URL', 'http://localhost:3000')}/approval_requests/#{@approval_request.id}"
    )
    ApprovalRequestMailer.approved(@approval_request).deliver_later
    redirect_to approval_request_path(@approval_request), notice: "承認しました"
  end

  def reject
    @approval_request.update!(
      status: :rejected,
      approved_by: current_user,
      approved_at: Time.current,
      rejection_reason: params.permit(:rejection_reason)[:rejection_reason]
    )
    TeamsNotifier.notify(
      title: "申請が却下されました",
      body: "「#{@approval_request.target_saas_name}」の利用申請が却下されました。\n理由: #{@approval_request.rejection_reason}",
      link: "#{ENV.fetch('APP_URL', 'http://localhost:3000')}/approval_requests/#{@approval_request.id}"
    )
    ApprovalRequestMailer.rejected(@approval_request).deliver_later
    redirect_to approval_request_path(@approval_request), notice: "却下しました"
  end

  private

  def set_approval_request
    @approval_request = ApprovalRequest.find(params[:id])
  end

  def authorize_show
    unless current_user.admin? || current_user.manager? || @approval_request.requester == current_user
      redirect_to approval_requests_path, alert: "閲覧権限がありません"
    end
  end

  def request_params
    params.require(:approval_request).permit(:request_type, :saas_id, :saas_name, :reason, :estimated_cost, :user_count, :approver_id)
  end
end
