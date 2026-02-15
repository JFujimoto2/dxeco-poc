class SurveyMailer < ApplicationMailer
  def distribution(survey)
    @survey = survey
    to_emails = survey.survey_responses.joins(:user).pluck("users.email").uniq
    return mail if to_emails.empty?

    mail(
      to: to_emails,
      subject: "[SaaS管理] サーベイのお願い: #{survey.title}"
    )
  end

  def reminder(survey)
    @survey = survey
    to_emails = survey.survey_responses.pending.joins(:user).pluck("users.email").uniq
    return mail if to_emails.empty?

    mail(
      to: to_emails,
      subject: "[SaaS管理] 【リマインド】サーベイ未回答: #{survey.title}"
    )
  end
end
