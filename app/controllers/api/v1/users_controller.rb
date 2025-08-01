# frozen_string_literal: true

class Api::V1::UsersController < Api::V1::ApplicationController
  before_action :find_user, only: %i[show]
  def show
    render json: Api::V1::UserSerializer.new(@user).as_json, status: :ok
  end

  def find_user
    @user = User.find_by!(uid: params[:id])
    authorize @user
  rescue ActiveRecord::RecordNotFound
    render json: {
             error: "User not found",
             message: "User with uid '#{params[:user_id]}' does not exist"
           },
           status: :not_found
  rescue Pundit::NotAuthorizedError
    render json: { error: "Not authorized" }, status: :unauthorized
  end
end
