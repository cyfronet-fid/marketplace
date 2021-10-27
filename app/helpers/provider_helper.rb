# frozen_string_literal: true

module ProviderHelper
  def data_for_map_provider(geographical_availabilities)
    countries = []
    geographical_availabilities.each do |place|
      co = []
      co = Country.countries_for_region(place&.name) if place
      co = [place] if co.empty?
      countries |= co if co.any?
    end
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
    fields.map { |f| record.send(f) }.any?(&:present?)
  end

  def field_tree(service, field)
    parents = service.send(field).map { |f| f.parent.presence || f }
    parents.map { |parent| [parent.name, (parent.children & service.send(field)).map(&:name)] }.to_h
  end
end
