class SurveysController < ApplicationController
  before_action :require_admin, only: [ :new, :create, :activate, :close, :remind ]

  def index
    @surveys = if current_user.admin?
      Survey.includes(:created_by).order(created_at: :desc).page(params[:page])
    else
      Survey.active.includes(:created_by).order(created_at: :desc).page(params[:page])
    end
  end

  def new
    @survey = Survey.new
    @saases = Saas.where(status: "active").order(:name)
    @departments = User.where.not(department: [ nil, "" ]).distinct.pluck(:department).sort
  end

  def create
    @survey = Survey.new(survey_params)
    @survey.created_by = current_user
    if @survey.save
      generate_responses(@survey)
      redirect_to survey_path(@survey), notice: "サーベイを作成しました"
    else
      @saases = Saas.where(status: "active").order(:name)
      @departments = User.where.not(department: [ nil, "" ]).distinct.pluck(:department).sort
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @survey = Survey.find(params[:id])
    if current_user.admin?
      @responses = @survey.survey_responses.includes(:user, saas_account: :saas).order(:user_id)
      @response_stats = {
        total: @survey.survey_responses.count,
        responded: @survey.survey_responses.responded.count,
        not_using: @survey.survey_responses.not_using.count
      }
    else
      @my_responses = @survey.survey_responses.where(user: current_user).includes(saas_account: :saas)
    end
  end

  def activate
    survey = Survey.find(params[:id])
    survey.update!(status: :active, sent_at: Time.current)
    TeamsNotifier.notify(
      title: "アカウントサーベイのお願い",
      body: "「#{survey.title}」への回答をお願いします。\n期限: #{survey.deadline&.strftime('%Y/%m/%d')}",
      webhook_url: TeamsNotifier::SURVEY_WEBHOOK_URL,
      link: "#{ENV.fetch('APP_URL', 'http://localhost:3000')}/surveys/#{survey.id}"
    )
    SurveyMailer.distribution(survey).deliver_later
    redirect_to survey_path(survey), notice: "サーベイを配信しました"
  end

  def close
    survey = Survey.find(params[:id])
    survey.update!(status: :closed)
    redirect_to survey_path(survey), notice: "サーベイを締め切りました"
  end

  def remind
    survey = Survey.find(params[:id])
    pending_count = survey.survey_responses.pending.select(:user_id).distinct.count
    TeamsNotifier.notify(
      title: "【リマインド】アカウントサーベイ未回答",
      body: "「#{survey.title}」に#{pending_count}名が未回答です。\n期限: #{survey.deadline&.strftime('%Y/%m/%d')}",
      webhook_url: TeamsNotifier::SURVEY_WEBHOOK_URL,
      link: "#{ENV.fetch('APP_URL', 'http://localhost:3000')}/surveys/#{survey.id}"
    )
    SurveyMailer.reminder(survey).deliver_later
    redirect_to survey_path(survey), notice: "リマインドを送信しました（未回答: #{pending_count}名）"
  end

  private

  def survey_params
    params.require(:survey).permit(:title, :survey_type, :deadline)
  end

  def generate_responses(survey)
    target_saas_ids = params.dig(:survey, :target_saas_ids)&.reject(&:blank?)
    department = params.dig(:survey, :target_department)

    accounts = SaasAccount.where(status: "active").includes(:user, :saas)
    accounts = accounts.where(saas_id: target_saas_ids) if target_saas_ids.present?
    accounts = accounts.joins(:user).where(users: { department: department }) if department.present?

    accounts.find_each do |account|
      survey.survey_responses.create!(
        user: account.user,
        saas_account: account
      )
    end
  end
end
