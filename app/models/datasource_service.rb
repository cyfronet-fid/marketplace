# frozen_string_literal: true

class DatasourceService < ApplicationRecord
  before_create :set_type

  belongs_to :datasource
  belongs_to :service, class_name: "Service", foreign_type: :type, optional: true, polymorphic: true

  validates :datasource, presence: true
  validates :service_id, presence: true
  validates :type, presence: true, inclusion: %w[RelatedService RequiredService]

  def set_type
    self.type = type
  end
end
