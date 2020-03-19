# frozen_string_literal: true

class Parameter
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :id, :name, :hint

  validates :id, presence: true
  validates :name, presence: true

  def initialize(attributes = {})
    attributes.each { |name, value| send("#{name}=", value) if respond_to?("#{name}=") }
  end

  def type
    self.class.type
  end

  def persisted?
    false
  end

  class << self
    def type
      class_name.underscore
    end

    def build(params)
      clazz = all.find { |c| c.type == params["type"] }
      clazz.new(params) if clazz
    end

    def all
      [Parameter::Input, Parameter::Select, Parameter::Multiselect,
       Parameter::Date, Parameter::Range, Parameter::QuantityPrice]
    end
  end
end
