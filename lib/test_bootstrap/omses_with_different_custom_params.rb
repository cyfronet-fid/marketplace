# frozen_string_literal: true

module TestBootstrap
  class OMSesWithDifferentCustomParams
    def call
      puts "Creating OMS2 (with two params, mandatory and not) and OMS3 (without params)"
      OMS.create!(
        name: "OMS2",
        type: "global",
        custom_params: {
          other_param_mandatory: {
            mandatory: true,
            default: "very needed"
          },
          yet_another: {
            mandatory: false
          }
        }
      )
      OMS.create!(name: "OMS3", type: "global", custom_params: {})
    end
  end
end
