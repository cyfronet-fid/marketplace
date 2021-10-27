# frozen_string_literal: true

module ProjectItem::Iid
  extend ActiveSupport::Concern

  included do
    validate :set_iid, on: :create
    validates :iid, presence: true, numericality: true
  end

  def to_param
    iid.to_s
  end

  private

  def set_iid
    self.iid = project.project_items.maximum(:iid).to_i + 1 if project && iid.blank?
  end
end
