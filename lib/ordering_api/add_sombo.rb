# frozen_string_literal: true

module OrderingApi
  class AddSombo
    def initialize; end

    def call
      sombo_admin = User.find_or_create_by(uid: "iamasomboadmin") do |user|
        user.first_name = "SOMBO admin"
        user.last_name = "SOMBO admin"
        user.email = "sombo@sombo.com"
      end

      sombo = OMS.find_or_create_by(name: "SOMBO") do |oms|
        oms.type = :global
        oms.default = true
        oms.custom_params = { order_target: { mandatory: false } }
        oms.administrators = [sombo_admin]
      end

      Service.all.each do |s|
        s.offers.each do |o|
          if o.current_oms == sombo && s.order_target.present?
            o.update(oms_params: { order_target: s.order_target })
          end
        end
      end
    end
  end
end
