# frozen_string_literal: true

class ProjectItem::Question
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :text, :author, :project_item

  validates :text, presence: { message: "Question cannot be blank" }
  validates :author, presence: true
  validates :project_item, presence: true

  def initialize(attributes = {})
    attributes.each { |name, value| send("#{name}=", value) }
  end

  def persisted?
    false
  end
end
