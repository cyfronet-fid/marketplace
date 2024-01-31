# frozen_string_literal: true

module OrderingApi
  class AddSombo
    def call
      sombo_admin =
        User
          .default_scoped
          .find_or_create_by(uid: "iamasomboadmin") do |user|
            user.first_name = "SOMBO admin"
            user.last_name = "SOMBO admin"
            user.email = "sombo@sombo.com"
          end

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
  end
end
