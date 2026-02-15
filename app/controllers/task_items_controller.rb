class TaskItemsController < ApplicationController
  def update
    item = TaskItem.find(params[:id])
    task = item.task

    unless current_user.admin? || current_user.manager? || task.created_by == current_user || item.assignee == current_user
      redirect_to root_path, alert: "更新権限がありません"
      return
    end

    if params[:complete] == "true"
      item.complete!
    else
      item.update!(status: :pending, completed_at: nil)
    end

    if task.task_items.all?(&:completed?)
      task.update!(status: :completed)
    elsif task.open?
      task.update!(status: :in_progress)
    end

    redirect_to task_path(task)
  end
end
