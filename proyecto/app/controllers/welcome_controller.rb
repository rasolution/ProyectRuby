class WelcomeController < ApplicationController
  skip_before_action :authenticate, only: [:index, :signin]

  def index
  end

  def signin
    credentials = params.require(:user).permit(:username, :password)
    user = User.find_by(username: credentials[:username].to_s.strip)
    if user && user.authenticate_compatible(credentials[:password].to_s)
      key = ApiKey.find_or_initialize_by(username: user.username)
      key.current = Time.current
      key.save!
      response.set_header('Cache-Control', 'no-store')
      render json: { status: 200, auth_token: key.access_token, username: user.username,
                     expires_at: (key.current + ApiKey::SESSION_TTL).iso8601 }, status: :ok
    else
      render json: { error: 'Usuario o contraseña incorrectos.' }, status: :unauthorized
    end
  end

  def signout
    current_key.destroy!
    render json: { status: 200 }
  end
end
