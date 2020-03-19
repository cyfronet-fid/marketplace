# frozen_string_literal: true

class AttributeTemplate
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :id, :name, :hint

  validates :id, presence: true
  validates :name, presence: true

  def initialize(attributes = {})
    attributes.each { |name, value| send("#{name}=", value) if respond_to?("#{name}=") }
  end

  def self.type
    class_name.underscore
  end

  def self.build(params)
    clazz = all.find { |c| c.type == params["type"] }

    puts "build attribute template: #{params}"
    clazz.new(params) if clazz
  end

  def self.all
    [AttributeTemplate::Input, AttributeTemplate::Select,
    AttributeTemplate::Multiselect, AttributeTemplate::Date,
    AttributeTemplate::Range, AttributeTemplate::QuantityPrice]
  end

  def type
    self.class.type
  end

  def persisted?
    false
  end
end
