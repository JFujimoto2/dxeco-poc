class TaskItemsController < ApplicationController
  def update
    item = TaskItem.find(params[:id])
    if params[:complete] == "true"
      item.complete!
    else
      item.update!(status: :pending, completed_at: nil)
    end

    task = item.task
    if task.task_items.all?(&:completed?)
      task.update!(status: :completed)
    elsif task.open?
      task.update!(status: :in_progress)
    end

    redirect_to task_path(task)
  end
end
