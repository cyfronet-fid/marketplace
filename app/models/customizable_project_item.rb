# frozen_string_literal: true

class CustomizableProjectItem < ProjectItem
  validate :validate_property_values
  validates_associated :property_values

  def property_values
    offer_values.attributes_map[offer]
  end

  def property_values=(property_values)
    offer_values.update(offer.id => property_values)
    self.properties = offer_values.to_hash
  end

  def bundled_property_values
    offer_values.attributes_map.reject { |o, _| o == offer }
  end

  def bundled_property_values=(bundled_property_values)
    bundled_property_values.each do |offer_id, property_values|
      offer = id_to_bundled_offer[offer_id]
      offer_values.update(offer.id => property_values) if offer
    end
    self.properties = offer_values.to_hash
  end

  private

  def validate_property_values
    offer_values.validate
  end

  def offer_values
    @offers_values ||= ProjectItem::OfferValues.new(offer: offer,
                                                    parameters: properties)
  end

  def id_to_bundled_offer
    @id_to_offer ||= offer.bundled_offers.index_by { |o| "o#{o.id}" }
  end
end
