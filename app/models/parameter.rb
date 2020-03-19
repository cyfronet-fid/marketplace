# frozen_string_literal: true

class Parameter
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :id, :name, :hint

  validates :id, presence: true
  validates :name, presence: true

  def initialize(attrs = {})
    attrs.each do |name, value|
      send("#{name}=", value) if respond_to?("#{name}=")
    end
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

    def for_type(params)
      all.find { |c| c.type == params["type"] }
    end

    def all
      [Parameter::Input, Parameter::Select, Parameter::Multiselect,
       Parameter::Date, Parameter::Range, Parameter::QuantityPrice]
    end
  end

  class Array
    class << self
      def load(hsh)
        hsh&.map { |params| Parameter.for_type(params).load(params) }
      end

      def dump(list)
        list&.map { |parameter| parameter.dump }
      end
    end
  end
end
