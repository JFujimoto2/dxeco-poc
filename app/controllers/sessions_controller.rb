class SessionsController < ApplicationController
  skip_before_action :require_login

  # GET /login
  def new
  end

  # POST /auth/entra_id/callback (OmniAuth callback)
  def create
    auth = request.env["omniauth.auth"]
    Rails.logger.info "[SSO] OmniAuth uid=#{auth.uid}, email=#{auth.info.email}, name=#{auth.info.name}"
    Rails.logger.info "[SSO] OmniAuth info: #{auth.info.to_h}"
    Rails.logger.info "[SSO] OmniAuth extra.raw_info: #{auth.extra&.raw_info&.to_h}" if auth.extra&.raw_info

    entra_id = auth.extra&.raw_info&.[]("oid") || auth.uid
    user = User.find_by(entra_id_sub: entra_id) || User.find_by(email: auth.info.email) || User.new
    user.entra_id_sub = entra_id
    user.assign_attributes(
      email: auth.info.email,
      display_name: auth.info.name,
      last_signed_in_at: Time.current
    )

    if auth.credentials&.token.present?
      profile = EntraClient.fetch_my_profile(auth.credentials.token)
      if profile
        Rails.logger.info "[SSO] Graph API /me response: #{profile}"
        user.department = profile["department"] if profile["department"].present?
        user.job_title = profile["jobTitle"] if profile["jobTitle"].present?
        user.employee_id = profile["employeeId"] if profile["employeeId"].present?
      else
        Rails.logger.warn "[SSO] Graph API profile fetch failed for #{auth.info.email}"
      end
    end

    user.role ||= "viewer"
    user.save!

    session[:user_id] = user.id
    session[:login_method] = :sso
    redirect_to root_path, notice: "ログインしました"
  end

  # GET /auth/failure
  def failure
    redirect_to login_path, alert: "認証に失敗しました: #{params[:message]}"
  end

  # DELETE /logout
  def destroy
    sso_login = session[:login_method].to_s == "sso"
    reset_session
    if sso_login && entra_id_configured?
      redirect_to "https://login.microsoftonline.com/#{ENV['ENTRA_TENANT_ID']}/oauth2/v2.0/logout?post_logout_redirect_uri=#{ERB::Util.url_encode(ENV.fetch('APP_URL', 'http://localhost:3000'))}", allow_other_host: true
    else
      redirect_to login_path, notice: "ログアウトしました"
    end
  end

  # POST /dev_login (開発環境のみ)
  def dev_create
    return head :forbidden unless Rails.env.development? || Rails.env.test?

    user = User.find_or_initialize_by(email: params[:email])
    if user.new_record?
      user.assign_attributes(
        entra_id_sub: SecureRandom.uuid,
        display_name: params[:display_name],
        role: params[:role].presence || "admin"
      )
    end
    user.last_signed_in_at = Time.current
    user.save!

    session[:user_id] = user.id
    redirect_to root_path, notice: "開発ログインしました"
  end
end
