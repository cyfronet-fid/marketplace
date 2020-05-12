# frozen_string_literal: true

class Profile::UsersController < ApplicationController
  before_action :authenticate_user!

  def show
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    attributes = permitted_attributes(@user)
    if Profile::Update.new(@user, attributes).call
      redirect_to profile_path,
                  notice: "Profile updated correctly"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    @user = current_user
    if Profile::Destroy.new(@user).call
      redirect_to root_path,
                  notice: "Profile deleted successfully"
    end
  end
end
