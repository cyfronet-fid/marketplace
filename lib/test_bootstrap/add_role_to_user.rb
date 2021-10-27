# frozen_string_literal: true

module TestBootstrap
  class AddRoleToUser
    def initialize(email, role)
      @email = email
      @role = role
    end

    def call
      Rails.logger.debug { "Adding role '#{@role}' to user with email '#{@email}'" }
      user = User.find_by!(email: @email)

      if User.valid_roles.exclude?(@role.to_sym)
        Rails.logger.debug { "Role must be a valid role, i.e. one of #{User.valid_roles}" }
        return
      end

      user.roles << @role
      user.save!
    end
  end
end
