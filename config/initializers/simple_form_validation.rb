# frozen_string_literal: true

module SimpleForm
  module Inputs
    class Base
      private
        def valid_validator?(validator)
          # conditional validators are no surprise
          # to us, so just check the action:
          action_validator_match?(validator)
        end
    end
  end
end
