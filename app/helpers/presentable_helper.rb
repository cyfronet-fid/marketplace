# frozen_string_literal: true

module PresentableHelper
  def data_for_map(geographical_availabilities)
    countries = []
    geographical_availabilities.each do |place|
      co = []
      co = Country.countries_for_region(place&.iso_short_name) if place
      co = [place] if co.empty?
      countries |= co if co.any?
    end
    countries
      .map(&:alpha2)
      .map { |c| [c.downcase, 1] }
      .map { |c| c == ["uk", 1] ? ["gb", 1] : c }
      .map { |c| c == ["el", 1] ? ["gr", 1] : c }
  end

  def data_for_region(countries)
    countries.append("WW") if any_non_european?(countries) && (countries != ["EO"]) && (countries != ["EU"])
    countries
  end

  def any_present?(record, *fields)
    fields.any? { |f| record.send(f).present? }
  end

  def field_tree(record, field)
    parents = record.send(field).map { |f| f.parent.blank? ? f : f.parent }
    parents.to_h { |parent| [parent.name, (parent.children & record.send(field)).map(&:name)] }
  end

  def presentable_logo(object, classes = "align-self-center mr-4 float-left img-responsive", resize = "100x67")
    if object.logo.attached? && object.logo.variable?
      image_tag object.logo.variant(resize: resize), class: classes
    else
      image_pack_tag("eosc-img.png", size: resize, class: classes)
    end
  end

  private

  def any_non_european?(countries)
    (countries - Country.countries_for_region("Europe").map(&:alpha2)).present?
  end
end
