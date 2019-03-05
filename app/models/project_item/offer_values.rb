# frozen_string_literal: true

class ProjectItem::OfferValues
  attr_reader :offer, :parts

  def initialize(offer:, parameters: nil)
    @offer = offer
    @main = ProjectItem::Part.new(offer: offer, parameters: parameters)
    @parts = bundled_parts(parameters&.[]("bundled_services") || [])
  end

  def attributes_map
    all_parts.map { |p| [p.offer, p.attributes] }.to_h
  end

  def update(values)
    id_to_part = all_parts.map { |p| [p.id.to_s, p] }.to_h
    values.each do |id, part_values|
      part = id_to_part[id.to_s]
      part.update(part_values) if part
    end
  end

  def validate
    all_parts.map { |p| p.validate }.all?
  end

  def to_hash
    @main.to_hash.tap do |hsh|
      hsh["bundled_services"] = @parts.map { |p| p.to_hash } if @parts.present?
    end
  end

  private

    def all_parts
      @parts + [@main]
    end

    def bundled_parts(parameters)
      id_to_part_parameters = parameters.map { |p| [p["offer_id"], p] }.to_h
      offer.bundled_offers.map do |offer|
        ProjectItem::Part.new(offer: offer,
                              parameters: id_to_part_parameters[offer.id])
      end
    end
end
