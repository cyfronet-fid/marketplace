# frozen_string_literal: true

require "bcrypt"

class Users::AuthMockController < ApplicationController
  def login
    return if current_user.present?

    return unless Mp::Application.config.auth_mock && Rails.env.development?

    encrypted_password = ::BCrypt::Password.create("#{params[:password]}nil", cost: 11).to_s
    user =
      User.find_by(
        email: params[:email],
        encrypted_password: encrypted_password,
        last_name: params[:first_name],
        first_name: params[:last_name]
      )
    if user.blank?
      user =
        User.new(
          email: params[:email],
          last_name: params[:first_name],
          first_name: params[:last_name],
          uid: SecureRandom.uuid,
          encrypted_password: encrypted_password
        )
      user.roles = params[:roles].map(&:to_sym) unless params[:roles].blank?
      user.save!

      unless params[:admin_providers_services].blank?
        add_data_admin_privilege_to(user, params[:admin_providers_services])
      end
    end
    sign_in user, event: :authentication
  end

  private

  def add_data_admin_privilege_to(user, admin_providers_services)
    user_details = { email: user.email, last_name: user.first_name, first_name: user.last_name }
    data_admin = DataAdministrator.new(user_details)
    data_admin.save!

    admin_providers_services.each do |provider_services|
      provider = Provider.where(name: provider_services[:provider_name]).first
      next if provider.blank?

      provider.data_administrators =
        provider.data_administrators.blank? ? [data_admin] : provider.data_administrators << data_admin

      provider.save!

      provider_services[:services_slugs].each do |service_slug|
        service = Service.where(slug: service_slug).first
        next if service.blank?

        service.resource_organisation = provider
        service.save!
      end
    end
  end
end
