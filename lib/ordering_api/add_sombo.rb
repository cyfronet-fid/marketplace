# frozen_string_literal: true

module OrderingApi
  class AddSombo
    def call
      sombo_admin =
        if Mp::Variant.pl?
          Users::Authenticate.call(auth_params)
        else
          User
            .default_scoped
            .find_or_create_by(uid: "iamasomboadmin") do |user|
              user.first_name = "SOMBO admin"
              user.last_name = "SOMBO admin"
              user.email = "sombo@sombo.com"
            end
        end
      sombo_admin.update!(roles_mask: 7) if Mp::Variant.pl?

      sombo =
        OMS
          .default_scoped
          .find_or_create_by(name: "SOMBO") do |oms|
            oms.type = :global
            oms.default = true
            oms.custom_params = { order_target: { mandatory: false } }
          end

      sombo.administrators << sombo_admin unless sombo.administrators.include?(sombo_admin)
    end

    private

    def auth_params
      {
        "provider" => "checkin",
        "uid" => "iamasomboadmin",
        "info" => {
          "email" => "sombo@sombo.com",
          "first_name" => "SOMBO admin",
          "last_name" => "SOMBO admin",
          "email_verified" => true
        }
      }
    end
  end
end
