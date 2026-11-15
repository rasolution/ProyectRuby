class WelcomeController < ApplicationController
  def index
  end

  def signin
    credentials = params.require(:user).permit(:username, :password)
    user = User.find_by(username: credentials[:username])
    digest = Digest::MD5.hexdigest(credentials[:password].to_s)
    if user && ActiveSupport::SecurityUtils.secure_compare(user.password.to_s, digest)
      # La identidad debe proceder del usuario autenticado, no de otro parámetro
      # vacío que antes hacía que diferentes usuarios compartieran la misma clave.
      key = ApiKey.find_or_initialize_by(username: user.username)
      key.current = Time.current
      key.save!
      render json: { status: 200, auth_token: key.access_token }, status: :ok
    else
      render json: { status: 401, response: { error: 'Username or password invalid.' } }, status: :unauthorized
    end
  end

  def signout
    key = ApiKey.find_by(access_token: request.headers['Authorization'])
    if key
      key.destroy!
      render json: { status: 200 }
    else
      render json: { status: 401, error: 'Token not found.' }, status: :unauthorized
    end
  end
end
