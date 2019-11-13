# frozen_string_literal: true

module ProjectItem::Customization
  extend ActiveSupport::Concern

  included do
    validate do
      property_values
        .select { |pv| pv.invalid? }
        .each { |pv| errors.add(:property_values, :invalid, value: pv) }
    end
  end


  def property_values
    part.attributes
  end

  def property_values=(property_values)
    part.update(property_values)
    self.properties = part.to_json
  end

  private

    def part
      @part ||= ProjectItem::Attributes.new(offer: offer, parameters: properties)
    end
end
