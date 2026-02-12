class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :require_login
  before_action :set_current_attributes

  private

  def set_current_attributes
    Current.user = current_user
    Current.ip_address = request.remote_ip
  end

  def require_login
    unless current_user
      redirect_to login_path
    end
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end
  helper_method :current_user

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "管理者権限が必要です"
    end
  end

  def require_admin_or_manager
    unless current_user&.admin? || current_user&.manager?
      redirect_to root_path, alert: "管理者またはマネージャー権限が必要です"
    end
  end

  def entra_id_configured?
    ENV["ENTRA_CLIENT_ID"].present?
  end
  helper_method :entra_id_configured?
end
