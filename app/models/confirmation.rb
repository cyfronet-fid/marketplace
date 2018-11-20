# frozen_string_literal: true

class Confirmation
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :required

  validates :terms_and_conditions, acceptance: true, presence: true, if: Proc.new { |u| u.required.present? }

  def initialize(attributes = {})
    attributes.each { |name, value| send("#{name}=", value) }
  end

  def persisted?
    false
  end
end
