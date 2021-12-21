# frozen_string_literal: true

class ArrayValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, values)
    Array(values).each do |value|
      options.each do |key, args|
        validator_options = { attributes: attribute }
        validator_options.merge!(args) if args.is_a?(Hash)

        next if value.blank? && !validator_options[:presence]

        validator_class_name = "#{key.to_s.camelize}Validator"
        validator_class =
          begin
            validator_class_name.constantize
          rescue NameError
            "ActiveModel::Validations::#{validator_class_name}".constantize
          end

        validator = validator_class.new(validator_options)
        validator.validate_each(record, attribute, value)
      end
    end
  end
end
