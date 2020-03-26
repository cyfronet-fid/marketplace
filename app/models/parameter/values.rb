# frozen_string_literal: true

module Parameter::Values
  extend ActiveSupport::Concern

  included do
    attribute :values, :string_array
    attribute :value_type, :string

    validates :value_type, presence: true, inclusion: %w[string integer]
    validates :values, presence: true
    validate :correct_values_type
  end

  private
    def correct_values_type
      values.each { |v| Integer(v) } if value_type == "integer"
    rescue
      errors.add(:values, "has elements with wrong type")
    end

    def cast(values)
      if value_type == "integer"
        values.map { |v| Integer(v) rescue String(v) }
      else
        values
      end
    end
end
