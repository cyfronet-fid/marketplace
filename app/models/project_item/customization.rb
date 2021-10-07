# frozen_string_literal: true

module ProjectItem::Customization
  extend ActiveSupport::Concern

  included do
    validate do
      # if offer.bundle?
      #   bundled_property_values.each do |offer, parameters|
      #     parameters
      #       .select { |pv| pv.invalid? }
      #       .each { |pv| errors.add(:property_values, :invalid, value: pv) }
      #   end
      # end
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

  def bundled_property_values
    offer_values.attributes_map.reject { |o, _| o == offer }
  end

  def bundled_property_values=(bundled_property_values)
    bundled_property_values.each do |offer_id, property_values|
      offer = id_to_bundled_offer[offer_id]
      offer_values.update(offer.id => property_values) if offer
    end
    self.properties
  end

  private
    def part
      @part ||= ProjectItem::Attributes.new(offer: offer, parameters: properties)
    end

    def offer_values
      @offers_values ||= ProjectItem::OfferValues.new(offer: offer,
                                                      parameters: properties)
    end

    def id_to_bundled_offer
      @id_to_offer ||= offer.bundled_offers.index_by { |o| "o#{o.id}" }
    end
end
