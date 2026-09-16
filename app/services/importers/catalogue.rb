# frozen_string_literal: true

class Importers::Catalogue < ApplicationService
  include Importable

  def initialize(data, synchronized_at)
    super()

    @data = data
    @synchronized_at = synchronized_at
  end

  def call
    {
      pid: data["id"],
      name: data["name"],
      description: data["description"],
      website: data["webpage"],
      tag_list: Array(data["tags"]),
      scientific_domains: scientific_domains,
      public_contacts: public_contacts,
      main_contact: main_contact,
      status: :published,
      synchronized_at: synchronized_at
    }
  end

  private

  attr_reader :data, :synchronized_at

  def main_contact
    return unless data["mainContact"].is_a?(Hash)

    contact_attributes = map_contact(data["mainContact"])
    MainContact.new(contact_attributes)
  end

  def public_contacts
    contact_emails = extract_public_contact_emails(data["publicContacts"])
    contact_emails.map { |email| PublicContact.new(email: email) }
  end

  def scientific_domains
    eids = scientific_domain_eids(data["scientificDomains"])
    map_scientific_domains(eids)
  end
end
