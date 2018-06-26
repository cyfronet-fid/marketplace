# frozen_string_literal: true

class Order::Question
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :text, :author, :order

  validates :text, presence: { message: "Question cannot be blank" }
  validates :author, presence: true
  validates :order, presence: true

  def initialize(attributes = {})
    attributes.each { |name, value| send("#{name}=", value) }
  end

  def persisted?
    false
  end
end
