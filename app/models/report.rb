# frozen_string_literal: true

class Report
  include ActiveModel::Serialization
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :text, :author, :email

  validates :text, presence: { message: "Description cannot be blank" }
  validates :author, presence: true
  validates :email, presence: true, email: true

  def initialize(attributes = {})
    attributes.each { |name, value| send("#{name}=", value) }
  end

  def persisted?
    false
  end

  class << self
    def load(json)
      return nil if json.blank?
      sliced = JSON.parse(json).slice("author", "email", "text")
      self.new(sliced)
    end

    def dump(obj)
      return nil if obj.blank?
      obj.to_json
    end
  end
end
