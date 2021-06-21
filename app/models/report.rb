# frozen_string_literal: true

class Report
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :text, :author, :email, :verified_recaptcha

  validates :text, presence: { message: "Description cannot be blank" }
  validates :author, presence: true
  validates :email, presence: true, email: true

  def initialize(attributes = {})
    attributes.each { |name, value| send("#{name}=", value) }
  end

  def persisted?
    false
  end
end
