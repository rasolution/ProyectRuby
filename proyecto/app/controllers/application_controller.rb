class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session
  before_action :authenticate, except: [:signin]

  protected

  def authenticate
    token = request.headers['Authorization'].to_s
    unless token.present? && ApiKey.exists?(access_token: token)
      render json: { status: 401, response: 'No access to do that' }, status: :unauthorized
    end
  end
end
