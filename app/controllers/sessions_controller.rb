class SessionsController < ApplicationController
  def login
  end

  def create
    user = User.find_by(email: params[:email])

    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to root_path, notice: "Logged in."
    else
      flash.now[:alert] = "Wrong email or password."
      render :login
    end
  end

  def destroy
      reset_session
      redirect_to root_path, notice: "Logged out"
  end
end
