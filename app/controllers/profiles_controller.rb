# frozen_string_literal: true

class ProfilesController < ApplicationController
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
      redirect_to profile_path, notice: "Profile updated successfully"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    @user = current_user
    redirect_to profile_path, notice: "Profile information removed successfully" if Profile::Destroy.new(@user).call
  end
end
