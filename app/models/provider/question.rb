# frozen_string_literal: true

class Provider::Question
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :text, :author, :provider, :email, :verified_recaptcha

  validates :text, presence: { message: "Question cannot be blank" }
  validates :author, presence: true
  validates :email, presence: true, email: true
  validates :provider, presence: true

  def initialize(attributes = {})
    attributes.each { |name, value| send("#{name}=", value) }
  end

  def persisted?
    false
  end
end
