# frozen_string_literal: true

module Importable
  class ResourceParseError < StandardError
  end

  class WrongMessageError < StandardError
  end

  class WrongIdError < StandardError
  end

  def object_status(active, suspended)
    current = active ? :published : :unpublished
    suspended && active ? :suspended : current
  end

  def map_alternative_identifier(identifier)
    AlternativeIdentifier.new(identifier_type: identifier["type"], value: identifier["value"]) if identifier.present?
  end

  def map_categories(categories)
    Category.where(eid: categories)
  end

  def map_nodes(nodes)
    Vocabulary::Node.where(eid: nodes)
  end

  def map_scientific_domains(domains)
    domains.present? ? ScientificDomain.where(eid: domains) : []
  end

  def map_link(link, type = "multimedia")
    return if link&.[]("multimediaURL").blank? && !UrlHelper.url?(link)

    if type == "multimedia"
      Link::MultimediaUrl.new(
        name: link&.[]("multimediaName") || "",
        url: link.is_a?(Hash) ? link["multimediaURL"] : link
      )
    end
  end

  def map_contact(contact)
    contact&.transform_keys { |k| k.to_s.underscore } || nil
  end

  def map_data_administrator(data)
    { first_name: data["name"], last_name: data["surname"], email: data["email"] }
  end

  def map_access_types(access_types)
    Vocabulary::AccessType.where(eid: access_types)
  end

  def map_order_type(order_type)
    order_type.gsub("order_type-", "") unless order_type.blank?
  end

  def map_legal_statuses(statuses)
    Vocabulary::LegalStatus.where(eid: statuses)
  end

  def map_hosting_legal_entity(entities)
    Vocabulary::HostingLegalEntity.where(eid: entities)
  end

  def map_trl(trl)
    Vocabulary::Trl.where(eid: trl)
  end

  def map_networks(networks)
    Vocabulary::Network.where(eid: networks)
  end

  def map_catalogue(catalogue)
    Catalogue.find_by(pid: catalogue)
  end

  def map_jurisdiction(jurisdiction)
    Vocabulary::Jurisdiction.find_by(eid: jurisdiction)
  end

  def map_datasource_classification(classification)
    Vocabulary::DatasourceClassification.find_by(eid: classification)
  end

  def map_provider(prov_eid)
    if prov_eid.present?
      Provider.find_by(pid: prov_eid) ||
        Provider.joins(:sources).find_by(
          "provider_sources.source_type": "eosc_registry",
          "provider_sources.eid": prov_eid
        )
    end
  end

  def extract_public_contact_emails(raw)
    Array(raw).map { |c| c.is_a?(Hash) ? c["email"] : c }.map { |e| e.to_s.strip }.reject(&:blank?).uniq
  end

  def map_alt_pid(hash)
    return nil unless hash.is_a?(Hash)

    AlternativeIdentifier.new(identifier_type: hash["pidSchema"], value: hash["pid"])
  end

  def fetch_ppid(candidate = [])
    candidate = candidate.blank? ? nil : candidate&.find { |id| id["type"] == "EOSC PID" }
    candidate.blank? ? "" : candidate&.[]("value")
  rescue StandardError
    Rails.logger.warn "Could not fetch Persistent Identifier EOSC PID. Return blank string"
    ""
  end

  def fetch_ppid_from_alt_pids(alt_pids)
    hit = Array(alt_pids).find { |p| p.is_a?(Hash) && p["pidSchema"].to_s.casecmp("eosc pid").zero? }
    hit ? hit["pid"].to_s : ""
  rescue StandardError
    Rails.logger.warn "Could not fetch Persistent Identifier EOSC PID. Return blank string"
    ""
  end
end
