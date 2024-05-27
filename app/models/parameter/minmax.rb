# frozen_string_literal: true

module Parameter::Minmax
  extend ActiveSupport::Concern

  included do
    attribute :min, :integer
    attribute :max, :integer

    validates :min, numericality: true
    validates :max, numericality: true

    validates :min,
              numericality: {
                less_than_or_equal_to: lambda(&:max),
                message: "must be less or equal than maximum value"
              },
              if: :max

    validates :max,
              numericality: {
                greater_than_or_equal_to: lambda(&:min),
                message: "must be greater or equal than minimum value"
              },
              if: :min
  end
end
