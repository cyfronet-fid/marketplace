# frozen_string_literal: true

class ProjectItem::OfferValues
  attr_reader :offer, :parts

  def initialize(offer:, parameters: nil)
    @offer = offer
    @parts = parts_from_parameters(parameters || {})
  end

  def attributes_map
    @parts.map { |p| [p.offer, p.attributes] }.to_h
  end

  def update(values)
    id_to_part = @parts.map { |p| [p.id.to_s, p] }.to_h
    values.each do |id, part_values|
      part = id_to_part[id]
      part.update(part_values) if part
    end
  end

  def validate
    @parts.map { |p| p.validate }.all?
  end

  def to_hash
    @parts.map { |p| [p.id, p.to_hash] }.to_h
  end

  private

    def parts_from_parameters(all_parameters)
      (offer.bundled_offers + [offer]).map do |offer|
        ProjectItem::Part.new(offer: offer, parameters: all_parameters[offer.id.to_s])
      end
    end
end
