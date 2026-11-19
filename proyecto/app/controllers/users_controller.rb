class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def index
    @users = User.where(id: current_user.id)
  end

  def show; end
  def edit; end

  def new
    @user = User.new
  end

  def create
    return unless valid_password_input?
    @user = User.new(user_params.except(:password_challenge))
    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, status: :see_other, notice: 'Cuenta creada.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update
    return unless valid_password_input?
    attributes = user_params.to_h
    challenge = attributes.delete('password_challenge')
    if attributes['password'].present? && !@user.authenticate_compatible(challenge.to_s)
      render json: { errors: ['La contraseña actual no es correcta.'] }, status: :unprocessable_entity
      return
    end
    attributes.delete('password') if attributes['password'].blank?
    attributes.delete('password_confirmation') if attributes['password_confirmation'].blank?
    password_changed = attributes['password'].present?
    if @user.update(attributes)
      ApiKey.where(username: @user.username).delete_all if password_changed
      render :show, status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    User.transaction do
      ApiKey.where(username: @user.username).delete_all
      @user.destroy!
    end
    head :no_content
  end

  private

  def set_user
    @user = User.where(id: current_user.id).find(record_id)
  end

  def user_params
    params.require(:user).permit(:username, :password, :password_confirmation, :password_challenge)
  end

  def valid_password_input?
    invalid = [:password, :password_confirmation, :password_challenge].any? do |key|
      value = user_params[key]
      !value.nil? && (!value.is_a?(String) || value.include?("\0"))
    end
    if invalid
      render json: { errors: ['La contraseña debe ser texto válido sin bytes nulos.'] }, status: :unprocessable_entity
      return false
    end
    true
  end
end
