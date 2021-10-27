# frozen_string_literal: true

class ProjectItem::OfferValues
  attr_reader :offer, :parts

  def initialize(offer:, parameters: nil)
    @offer = offer
    @main = ProjectItem::Part.new(offer: offer, parameters: parameters)
    @parts = bundled_parts
  end

  def attributes_map(all = false)
    if all
      all_parts.map { |p| [p.offer, p.attributes] }.to_h
    else
      @parts.map { |p| [p.offer, p.attributes] }.to_h
    end
  end

  def update(values)
    id_to_part = all_parts.index_by { |p| p.offer.id.to_s }
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
      hsh["bundled_property_values"] = @parts.map { |p| p.to_hash } if @parts.present?
    end
  end

  def to_json(only_bundled = true)
    if only_bundled
      @parts.map { |part| [part.offer, part.attributes] }.to_h
    else
      {
        "property_values": @main.to_json,
        "bundled_property_values": @parts.map { |part| ["o#{part.offer.id}", part.to_json] }.to_h
      }
    end
  end

  private
    def all_parts
      @parts + [@main]
    end

    def bundled_parts
      offer.bundled_offers.map do |offer|
        ProjectItem::Part.new(offer: offer,
                              parameters: offer.parameters.map { |p| p.dump })
      end
    end
end
