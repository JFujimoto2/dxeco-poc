class TaskPresetsController < ApplicationController
  before_action :require_admin

  def index
    @presets = TaskPreset.includes(:task_preset_items).order(:task_type, :name)
  end

  def new
    @preset = TaskPreset.new
    @preset.task_preset_items.build
  end

  def create
    @preset = TaskPreset.new(preset_params)
    if @preset.save
      redirect_to task_presets_path, notice: "プリセットを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @preset = TaskPreset.find(params[:id])
  end

  def update
    @preset = TaskPreset.find(params[:id])
    if @preset.update(preset_params)
      redirect_to task_presets_path, notice: "プリセットを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    TaskPreset.find(params[:id]).destroy!
    redirect_to task_presets_path, notice: "プリセットを削除しました"
  end

  private

  def preset_params
    params.require(:task_preset).permit(
      :name, :task_type, :description,
      task_preset_items_attributes: [:id, :action_type, :description, :default_assignee_id, :position, :_destroy]
    )
  end
end
