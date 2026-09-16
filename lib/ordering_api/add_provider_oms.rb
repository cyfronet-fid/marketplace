# frozen_string_literal: true

module OrderingApi
  class AddProviderOMS
    def initialize(oms_name, provider_pid, authentication_token)
      @oms_name = oms_name.downcase
      @provider_pid = provider_pid
      @authentication_token = authentication_token
    end

    def call
      provider = Provider.find_by(pid: @provider_pid)
      if provider.blank?
        logger.info "Provider with pid '#{@provider_pid}' not found. It must exist to attach the OMS to it."
        return
      end

      admin =
        if Mp::Variant.pl?
          Users::Authenticate.call(auth_params)
        else
          User.find_or_initialize_by(uid: admin_uid) do |user|
            user.first_name = admin_first_name
            user.last_name = "admin"
            user.email = admin_email
          end
        end
      admin.authentication_token = @authentication_token if @authentication_token.present?
      admin.save!

      oms = OMS.find_or_initialize_by(name: "#{@oms_name.titlecase} OMS")
      oms.type = :provider_group
      append_if_not_present oms.providers, provider
      append_if_not_present oms.administrators, admin
      oms.save!

      logger.info "OMS id: #{oms.id}, name: '#{oms.name}', providers: #{oms.providers.pluck(:pid).join(", ")}"
      logger.info "Admin user uid: '#{admin_uid}', token: '#{admin.authentication_token}'"
    end

    private

    def auth_params
      {
        "provider" => "checkin",
        "uid" => admin_uid,
        "info" => {
          "email" => admin_email,
          "first_name" => admin_first_name,
          "last_name" => "admin",
          "email_verified" => true
        }
      }
    end

    def admin_uid
      "iama#{@oms_name}admin"
    end

    def admin_email
      "#{@oms_name}_admin@example.com"
    end

    def admin_first_name
      @oms_name.titlecase
    end

    def append_if_not_present(association, element)
      association << element if association.exclude?(element)
    end

    def logger
      Rails.logger
    end
  end
end
