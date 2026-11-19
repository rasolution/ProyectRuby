class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session
  before_action :authenticate
  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: 'El registro no existe.' }, status: :not_found
  end
  rescue_from ActionController::ParameterMissing do
    render json: { error: 'Faltan datos obligatorios en la solicitud.' }, status: :bad_request
  end

  protected

  attr_reader :current_user, :current_key

  def record_id
    value = params[:id].to_s
    raise ActiveRecord::RecordNotFound unless value.match?(/\A[1-9]\d{0,18}\z/)
    value
  end

  def authenticate
    token = request.headers['Authorization'].to_s.sub(/\ABearer\s+/i, '')
    @current_key = token.present? && token.length <= 128 ? ApiKey.find_by(access_token: token) : nil
    @current_user = User.find_by(username: @current_key.username) if @current_key
    unless @current_user && @current_key.current && @current_key.current >= ApiKey::SESSION_TTL.ago
      render json: { error: 'La sesión no es válida o ha vencido. Inicia sesión de nuevo.' }, status: :unauthorized
    end
  end
end
