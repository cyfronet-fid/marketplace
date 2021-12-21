# frozen_string_literal: true

module ProjectItem::Customizations
  extend ActiveSupport::Concern

  def customizations
    @customizations ||= properties["attributes"].map { |p| Attribute.from_json(p) }
  end

  def bundled_services
    @bundled_services ||=
      (properties["bundled_services"] || []).map { |parameters| ProjectItem::ReadonlyPart.new(parameters: parameters) }
  end
end
