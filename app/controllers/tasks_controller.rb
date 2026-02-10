class TasksController < ApplicationController
  before_action :require_admin, only: [:new, :create]

  def index
    @tasks = Task.includes(:target_user, :created_by)
    @tasks = @tasks.where(status: params[:status]) if params[:status].present?
    @tasks = @tasks.where(task_type: params[:task_type]) if params[:task_type].present?
    @tasks = @tasks.order(created_at: :desc).page(params[:page])
  end

  def new
    @task = Task.new
    @presets = TaskPreset.all
    @users = User.where(account_enabled: true).order(:display_name)

    if params[:preset_id].present? && params[:target_user_id].present?
      preset = TaskPreset.find(params[:preset_id])
      target_user = User.find(params[:target_user_id])
      @task.title = "#{target_user.display_name}の#{preset.name}"
      @task.task_type = preset.task_type
      @task.target_user = target_user
      @task.due_date = 2.weeks.from_now.to_date

      preset.task_preset_items.order(:position).each do |item|
        @task.task_items.build(
          action_type: item.action_type,
          description: item.description,
          assignee: item.default_assignee
        )
      end

      if preset.offboarding?
        target_user.saas_accounts.where(status: "active").includes(:saas).each do |account|
          @task.task_items.build(
            action_type: "account_delete",
            description: "#{account.saas.name} アカウント削除",
            saas: account.saas
          )
        end
      end

      if preset.onboarding?
        Saas.active.each do |saas|
          @task.task_items.build(
            action_type: "account_create",
            description: "#{saas.name} アカウント作成",
            saas: saas
          )
        end
      end
    end
  end

  def create
    @task = Task.new(task_params)
    @task.created_by = current_user
    if @task.save
      TeamsNotifier.notify(
        title: "新しいタスクが作成されました",
        body: "「#{@task.title}」\n期限: #{@task.due_date}\n項目数: #{@task.task_items.count}"
      )
      redirect_to @task, notice: "タスクを作成しました"
    else
      @presets = TaskPreset.all
      @users = User.where(account_enabled: true).order(:display_name)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @task = Task.find(params[:id])
    @task_items = @task.task_items.includes(:saas, :assignee).order(:id)
  end

  private

  def task_params
    params.require(:task).permit(
      :title, :task_type, :target_user_id, :due_date,
      task_items_attributes: [:action_type, :description, :saas_id, :assignee_id]
    )
  end
end
