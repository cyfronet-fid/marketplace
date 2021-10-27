# frozen_string_literal: true

class ProjectItem::OfferValues
  attr_reader :offer, :parts

  def initialize(offer:, parameters: nil)
    @offer = offer
    @main = ProjectItem::Part.new(offer: offer, parameters: parameters)
    @parts = bundled_parts
  end

  def attributes_map
    all_parts.map { |p| [p.offer, p.attributes] }.to_h
  end

  def update(values)
    id_to_part = all_parts.index_by { |p| p.id.to_s }
    values.each do |id, part_values|
      part = id_to_part[id.to_s]
      part&.update(part_values)
    end
  end

  def validate
    all_parts.map(&:validate).all?
  end

  def to_hash
    @main.to_hash.tap do |hsh|
      hsh["bundled_services"] = @parts.map(&:to_hash) if @parts.present?
    end
  end

  private

  def all_parts
    @parts + [@main]
  end

  def bundled_parts
    offer.bundled_offers.map do |offer|
      ProjectItem::Part.new(offer: offer,
                            parameters: offer.parameters.map(&:dump))
    end
  end
end
