class SurveyResponsesController < ApplicationController
  def update
    @response = SurveyResponse.find(params[:id])
    unless @response.user == current_user
      redirect_to surveys_path, alert: "権限がありません"
      return
    end
    @response.update!(response_params.merge(responded_at: Time.current))
    redirect_to survey_path(@response.survey), notice: "回答を保存しました"
  end

  private

  def response_params
    params.require(:survey_response).permit(:response, :notes)
  end
end
