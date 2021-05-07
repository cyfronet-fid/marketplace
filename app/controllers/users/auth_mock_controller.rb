# frozen_string_literal: true

require "bcrypt"

class Users::AuthMockController < ApplicationController
  def login
    if current_user.present?
      return
    end

    unless Mp::Application.config.auth_mock && Rails.env.development?
      return
    end

    encrypted_password = ::BCrypt::Password.create(
      "#{params[:password]}#{nil}",
      cost: 11
    ).to_s

    @user = User.find_by(
      email: params[:email],
      encrypted_password: encrypted_password,
      last_name: params[:first_name],
      first_name: params[:last_name]
    )
    if @user.blank?
      @user = User.new(
        email: params[:email],
        last_name: params[:first_name],
        first_name: params[:last_name],
        uid: SecureRandom.uuid,
        encrypted_password: encrypted_password
      )
      @user.save
    end
    sign_in @user, event: :authentication
  end
end
