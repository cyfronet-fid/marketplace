# frozen_string_literal: true

module ProviderHelper
  def data_for_map_provider(geographical_availabilities)
    countries = []
    geographical_availabilities.each { |place|
      co = []
      co = Country.countries_for_region(place&.name) if place
      co = [place] if co.empty?
      countries = countries | co if co.any?
    }
    countries.map(&:alpha2).map { |c| [c.downcase, 1] }
                         .map { |c| c == ["uk", 1] ? ["gb", 1] : c }
                         .map { |c| c == ["el", 1] ? ["gr", 1] : c }
  end

  def data_for_region_provider(countries)
    if is_any_non_european(countries) &&
      (countries != ["EO"]) &&
      (countries != ["EU"])
      countries.append("WW")
    end
    countries
  end

  def provider_any_present?(record, *fields)
    fields.map { |f| record.send(f) }.any? { |v| v.present? }
  end

  def provider_logo(provider, classes = "align-self-center mr-4 float-left img-responsive", resize = "100x67")
    if provider.logo.attached? && provider.logo.variable?
      image_tag provider.logo.variant(resize: resize), class: classes
    else
      image_pack_tag("eosc-img.png", size: resize, class: classes)
    end
  end

  def field_tree(service, field)
    parents = service.send(field).map { |f| f.parent.blank? ? f : f.parent }
    Hash[parents.map { |parent| [parent.name, (parent.children & service.send(field)).map(&:name)] } ]
  end
end
