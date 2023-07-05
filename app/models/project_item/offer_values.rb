# frozen_string_literal: true

class ProjectItem::OfferValues
  attr_reader :offer, :bundle, :parts

  def initialize(offer:, bundle:, parameters: nil)
    @offer = offer || bundle.main_offer
    @bundle = bundle
    @parameters = parameters
    @main = ProjectItem::Part.new(offer: offer, parameters: parameters)
    @parts = bundled_parts
  end

  def attributes_map
    @parts.to_h { |p| [p.offer, p.attributes] }
  end

  def update(values)
    id_to_part = all_parts.index_by { |p| p.offer.id.to_s }
    values.each do |id, part_values|
      part = id_to_part[id.to_s]
      part&.update(part_values)
    end
  end

  def validate
    all_parts&.map(&:validate)&.all?
  end

  def to_hash
    @main.to_hash.tap { |hsh| hsh["bundled_property_values"] = @parts.map(&:to_hash) if @parts.present? }
  end

  def to_json(*_args)
    @parts.to_h { |part| [part.offer, part.attributes] }
  end

  private

  def all_parts
    @parts + [@main]
  end

  def bundled_parts
    if @bundle.present?
      @bundle.offers.map { |offer| ProjectItem::Part.new(offer: offer, parameters: offer.parameters.map(&:dump)) }
    end
  end
end
