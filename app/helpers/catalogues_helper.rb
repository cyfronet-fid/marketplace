# frozen_string_literal: true

module CataloguesHelper
  def format_city_region(catalogue)
    if catalogue.city.present? && catalogue.region.present?
      "#{catalogue.city}, #{catalogue.region}"
    elsif catalogue.city.present?
      catalogue.city
    elsif catalogue.region.present?
      catalogue.region
    else
      "-"
    end
  end

  def format_main_contact_name(catalogue)
    if catalogue.main_contact&.first_name && catalogue.main_contact.last_name
      return catalogue.main_contact.first_name + " " + catalogue.main_contact.last_name
    end

    "-"
  end

  def format_scientific_domains(catalogue)
    if catalogue.scientific_domains.present?
      return catalogue.scientific_domains.map { |sd| "#{sd.root.name}->#{sd.name}" }.join(", ")
    end

    "-"
  end

  def format_basic_link(link)
    link ? (link_to link, link, target: "_blank") : "-"
  end
end
