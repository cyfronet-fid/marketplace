# frozen_string_literal: true

class UpdateScientificDomains < ActiveRecord::Migration[6.0]
  def change
    eosc_scientific_domains = [
      "Natural Sciences",
      "Engineering & Technology",
      "Medical & Health Sciences",
      "Agricultural Sciences",
      "Social Sciences",
      "Humanities",
      "Generic",
      "Other",
      "Mathematics",
      "Computer & Information Sciences",
      "Physical Sciences",
      "Chemical Sciences",
      "Earth & Related Environmental Sciences",
      "Biological Sciences",
      "Other Natural Sciences",
      "Electrical, Electronic & Information Engineering",
      "Mechanical Engineering",
      "Chemical Engineering",
      "Materials Engineering",
      "Medical Engineering",
      "Environmental Engineering",
      "Environmental Biotechnology",
      "Industrial Biotechnology",
      "Nanotechnology",
      "Other Engineering & Technology Sciences",
      "Basic Medicine",
      "Clinical Medicine",
      "Health Sciences",
      "Medical Biotechnology",
      "Other Medical Sciences",
      "Agriculture, Forestry & Fisheries",
      "Animal & Dairy Sciences",
      "Veterinary Sciences",
      "Agricultural Biotechnology",
      "Other Agricultural Sciences",
      "Psychology",
      "Economics & Business",
      "Educational Sciences",
      "Sociology",
      "Law",
      "Political Sciences",
      "Social & Economic Geography",
      "Media & Communications",
      "Other Social Sciences",
      "History & Archaeology",
      "Languages & Literature",
      "Philosophy, Ethics & Religion",
      "Arts",
      "Other Humanities",
      "Generic",
      "Other",
      "Civil Engineering"
    ]
    domains_to_be_mapped = [
      "Philosophy, ethics and religion",
      "Social sciences",
      "Political sciences",
      "Engineering and Technology",
      "Electrical, electronic and information engineering",
      "Environmental engineering",
      "Medical and Health Sciences",
      "Earth Science",
      "Environmental science",
      "Physical science (earth science)",
      "Economics, Finance & Business",
      "Other Medical Science",
      "Nano-technology"
    ]

    ActiveRecord::Base.transaction do
      to_other = ScientificDomain.where.not(name: eosc_scientific_domains + domains_to_be_mapped)
      target_id = ScientificDomain.find_by(name: "Other", ancestry_depth: 1).id
      to_other
        .map(&:id)
        .each do |source_id|
          cast_and_remove_sources(ServiceScientificDomain, source_id, target_id, "service_id")
          cast_and_remove_sources(UserScientificDomain, source_id, target_id, "user_id")
          cast_and_remove_sources(ProviderScientificDomain, source_id, target_id, "provider_id")
          cast_and_remove_sources(ProjectScientificDomain, source_id, target_id, "project_id")
        end
      to_other.delete_all

      domains_map = {
        "Philosophy, ethics and religion": "Philosophy, Ethics & Religion",
        "Social sciences": "Other Social Sciences",
        "Political sciences": "Political Sciences",
        "Engineering and Technology": "Other Engineering & Technology Sciences",
        "Electrical, electronic and information engineering": "Electrical, Electronic & Information Engineering",
        "Environmental engineering": "Environmental Engineering",
        "Medical and Health Sciences": "Other Medical Sciences",
        "Earth Science": "Earth & Related Environmental Sciences",
        "Environmental science": "Earth & Related Environmental Sciences",
        "Physical science (earth science)": "Earth & Related Environmental Sciences",
        "Economics, Finance & Business": "Economics & Business",
        "Other Medical Science": "Other Medical Sciences",
        "Nano-technology": "Nanotechnology"
      }
      domains_map.each do |source_name, target_name|
        source = ScientificDomain.find_by(name: source_name, eid: nil)
        next if source.blank?

        source_id = source.id
        target_id = ScientificDomain.find_by(name: target_name).id
        cast_and_remove_sources(ServiceScientificDomain, source_id, target_id, "service_id")
        cast_and_remove_sources(UserScientificDomain, source_id, target_id, "user_id")
        cast_and_remove_sources(ProviderScientificDomain, source_id, target_id, "provider_id")
        cast_and_remove_sources(ProjectScientificDomain, source_id, target_id, "project_id")
        source.delete
      end
    rescue StandardError
      raise ActiveRecord::Rollback
    end
  end

  private

  def cast_and_remove_sources(domains_group, source_id, target_id, id_field_name)
    source_relation_ids =
      domains_group.where(scientific_domain_id: source_id).map { |sd| sd[id_field_name.to_sym] }.uniq
    target_relation_ids =
      domains_group.where(scientific_domain_id: target_id).map { |sd| sd[id_field_name.to_sym] }.uniq
    skip_update = source_relation_ids.blank?
    return if skip_update

    source_relation_ids_to_update =
      (source_relation_ids - target_relation_ids) | (target_relation_ids - source_relation_ids)
    only_remove = source_relation_ids_to_update.blank?
    if only_remove
      domains_group.where(scientific_domain_id: source_id).delete_all
      return
    end

    domains_group.where(id_field_name => source_relation_ids_to_update, :scientific_domain_id => source_id).update_all(
      scientific_domain_id: target_id
    )
    all_target_records = domains_group.where(scientific_domain_id: target_id).map { |sd| sd[id_field_name.to_sym] }.uniq
    unless all_target_records.length == (target_relation_ids + source_relation_ids).uniq.length
      raise StandardError("Not all sources have been casted")
    end
    domains_group.where(scientific_domain_id: source_id).delete_all
  end
end
