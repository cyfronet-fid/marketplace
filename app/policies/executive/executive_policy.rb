# frozen_string_literal: true

Executive::ExecutivePolicy =
  Struct.new(:user, :executive) do
    def show?
      user&.executive?
    end
  end
