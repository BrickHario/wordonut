class UsersController < ApplicationController
  before_action :require_login, only: [ :edit, :update_email, :update_password, :destroy ]
  before_action :set_user, only: [ :edit, :update_email, :update_password, :destroy ]

  def signin
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :signin
    end
  end

  def edit
  end

  def update_email
    if @user.update(email_params)
      redirect_to profile_path
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :edit
    end
  end

  def update_password
    if password_params[:password].blank?
      flash.now[:alert] = "Das Passwort darf nicht leer sein."
      render :edit
      return
    end

    if @user.update(password_params)
      redirect_to profile_path
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :edit
    end
  end

  def destroy
    if @user.destroy
      reset_session
      redirect_to root_path
    else
      flash[:alert] = "Fehler beim Löschen des Accounts."
      redirect_to profile_path
    end
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end

  def email_params
    params.require(:user).permit(:email)
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
