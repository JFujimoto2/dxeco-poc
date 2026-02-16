class TaskItemsController < ApplicationController
  before_action :set_task_item
  before_action :authorize_task_item

  def update
    if params[:complete] == "true"
      @item.complete!
    else
      @item.update!(status: :pending, completed_at: nil)
    end

    if @task.task_items.all?(&:completed?)
      @task.update!(status: :completed)
    elsif @task.open?
      @task.update!(status: :in_progress)
    end

    redirect_to task_path(@task)
  rescue ActiveRecord::RecordInvalid => e
    redirect_to task_path(@task), alert: "更新に失敗しました: #{e.record.errors.full_messages.join(', ')}"
  end

  private

  def set_task_item
    @item = TaskItem.find(params[:id])
    @task = @item.task
  end

  def authorize_task_item
    unless current_user.admin? || current_user.manager? || @task.created_by == current_user || @item.assignee == current_user
      redirect_to root_path, alert: "更新権限がありません"
    end
  end
end
