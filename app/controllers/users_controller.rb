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
      redirect_to root_path, notice: "Account successfully created."
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :signin
    end
  end

  def edit
  end

  def update_email
    if @user.update(email_params)
      redirect_to profile_path, notice: "Email successfully updated."
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :edit
    end
  end

  def update_password

    if password_params[:password] != password_params[:password_confirmation]
      flash.now[:alert] = "Passwords do not match."
      render :edit and return
    end

    if @user.authenticate(password_params[:password])
      flash.now[:alert] = "The new password must be different from the current password."
      render :edit and return
    end

    if @user.update(password_params)
      redirect_to profile_path, notice: "Password successfully updated."
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :edit
    end
  end

  def destroy
    if @user.destroy
      reset_session
      redirect_to root_path, notice: "Account successfully deleted."
    else
      flash[:alert] = "Error deleting account."
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
