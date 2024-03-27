# frozen_string_literal: true

module ProjectItem::Customization
  extend ActiveSupport::Concern

  included do
    validate do
      if bundle.present?
        bundled_property_values.to_h.each_value do |parameters|
          parameters.select(&:invalid?).each { |pv| errors.add(:bundled_property_values, :invalid, value: pv) }
        end
      end
      property_values.select(&:invalid?).each { |pv| errors.add(:property_values, :invalid, value: pv) }
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
    if defined?(bundled_parameters)
      if bundled_parameters.present?
        bundled_parameters.transform_keys { |offer| offer.instance_of?(Offer) ? offer : Offer.find(offer) }
      else
        offer_values.attributes_map.reject { |o, _| o == offer }
      end
    else
      []
    end
  end

  def bundled_property_values=(bundled_property_values)
    bundled_property_values.each do |offer_id, property_values|
      offer = id_to_bundled_offer[offer_id]
      offer_values.update(offer.id => property_values) if offer
    end
    self.bundled_parameters = offer_values.to_json
  end

  private

  def part
    @part ||= ProjectItem::Attributes.new(offer: offer, parameters: properties)
  end

  def offer_values
    @offer_values ||= ProjectItem::OfferValues.new(offer: offer, bundle: bundle, parameters: properties)
  end

  def id_to_bundled_offer
    @id_to_bundled_offer ||= bundle.offers.index_by { |o| "o#{o.id}" }
  end
end
