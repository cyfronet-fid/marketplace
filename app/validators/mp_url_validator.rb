# frozen_string_literal: true

require "public_suffix"

class MpUrlValidator < ActiveModel::EachValidator
  def initialize(options)
    options.reverse_merge!(schemes: %w(http https))
    options.reverse_merge!(message: :url)

    super(options)
  end

  def validate_each(record, attribute, value)
    schemes = [*options.fetch(:schemes)].map(&:to_s)
    begin
      uri = URI.parse(value)
      host = uri&.host
      scheme = uri&.scheme

      valid_suffix = host && PublicSuffix.valid?(host)
      valid_no_local = host&.include?(".")
      valid_scheme = host && scheme && schemes.include?(scheme)

      unless valid_scheme && valid_no_local && valid_suffix
        record.errors.add(attribute, options.fetch(:message), value: value)
      end

    rescue URI::InvalidURIError
      record.errors.add(attribute, options.fetch(:message), value: value)
    end
  end
end
