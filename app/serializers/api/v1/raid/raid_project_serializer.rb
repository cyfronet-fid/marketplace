# frozen_string_literal: true

class Api::V1::Raid::RaidProjectSerializer < ActiveModel::Serializer
  attribute :identifier
  attribute :date
  attribute :title
  attribute :description, if: -> { object.main_description.present? }
  attribute :organisation, if: -> { object.raid_organisations.present? }
  attribute :contributor
  attribute :access
  attribute(:alternateUrl) { nil }
  attribute(:subject) { nil }
  attribute(:relatedRaid) { nil }
  attribute(:relatedObject) { nil }
  attribute(:alternateIdentifier) { nil }
  attribute(:spatialCoverage) { nil }
  attribute(:traditionalKnowledgeLabel) { nil }

  def identifier
    {
      id: nil,
      schemaUri: "https://raid.org/",
      registrationAgency: {
        id: "https://ror.org/038sjwq14",
        schemaUri: "https://ror.org/"
      },
      owner: {
        id: "https://ror.org/038sjwq14",
        schemaUri: "https://ror.org/",
        servicePoint: 20_000_000
      },
      raidAgencyUrl: "http://localhost:808010.82841/619abd9d",
      license: "Creative Commons CC-0",
      version: 8
    }
  end

  def date
    { startDate: object.start_date, endDate: object.end_date }
  end

  def contributor
    contributors = []
    object.contributors.map { |c| contributors.append(serialize_contributor(c)) }
    contributors
  end

  def serialize_contributor(contr)
    c_roles = []
    id_schema = "https://#{contr.pid_type.downcase}.org/"
    contr.roles.each do |role|
      r = { schemaUri: "https://credit.niso.org/", id: "https://credit.niso.org/contributor-roles/#{role}/" }
      c_roles.append(r)
    end

    {
      id: "#{id_schema}#{contr.pid}",
      schemaUri: id_schema,
      position: [serialize_contributor_position(contr.position)],
      role: c_roles,
      leader: contr.leader,
      contact: contr.contact
    }
  end

  def description
    descriptions = []
    descriptions.append(serialize_description(object.main_description))
    object.alternative_descriptions.map { |d| descriptions.append(serialize_description(d)) }
    descriptions
  end

  def organisation
    organisations = []
    object.raid_organisations.map { |o| organisations.append(serialize_organisation(o)) }
    organisations
  end

  def serialize_organisation(org)
    { id: org.pid, schemaUri: "https://ror.org/", role: [serialize_organisation_role(org.position)] }
  end

  def serialize_contributor_position(position)
    serialized = get_contributor_position(position.pid)
    serialized[:startDate] = position.start_date
    serialized[:endDate] = position.end_date
    serialized
  end

  def serialize_organisation_role(role)
    serialized = get_organisation_role(role.pid)
    p serialized
    serialized[:startDate] = role.start_date
    serialized[:endDate] = role.end_date
    serialized
  end

  def title
    titles = []
    titles.append(serialize_title(object.main_title))
    object.alternative_titles.each { |t| titles.append(serialize_title(t)) }
    titles
  end

  def serialize_title(title)
    {
      text: title.text,
      type: get_title_type(title.title_type),
      startDate: title.start_date,
      endDate: title.end_date,
      language: get_language(title.language)
    }
  end

  def serialize_description(desc)
    { text: desc.text, type: get_description_type(desc.description_type), language: get_language(desc.language) }
  end

  def access
    return if object.raid_access.access_type == "open" && object.raid_access.statement_text.empty?
    {
      type: get_access_type(object.raid_access.access_type),
      statement: {
        text: object.raid_access.statement_text,
        language: get_language(object.raid_access.statement_lang)
      },
      embargoExpiry: object.raid_access.embargo_expiry
    }
  end

  def get_language(language)
    { id: language, schemaUri: "https://www.iso.org/standard/74575.html" }
  end

  def get_access_type(access_type)
    access_type_map = { open: "c_abf2", embargoed: "c_f1cf" }
    a_type = access_type_map[access_type.to_sym]
    if a_type.nil?
      p "Unpermitted access type" # TODO: error handling
      return
    end
    {
      id: "https://vocabularies.coar-repositories.org/access_rights/#{a_type}/",
      schemaUri: "https://vocabularies.coar-repositories.org/access_rights/"
    }
  end

  def get_title_type(title_type)
    schema = "https://vocabulary.raid.org/title.type.schema"
    type_pid = "376"
    title_type_map = { primary: "5", alternative: "4" }
    t_type = title_type_map[title_type.to_sym]
    if t_type.nil?
      p "Unpermitted title type" # TODO: error handling
      return
    end
    { id: "#{schema}/#{t_type}", schemaUri: "#{schema}/#{type_pid}" }
  end

  def get_description_type(description_type)
    schema = "https://vocabulary.raid.org/description.type.schema"
    type_pid = "320"
    description_type_map = { primary: "318", alternative: "319" }
    d_type = description_type_map[description_type.to_sym]
    if d_type.nil?
      p "Unpermitted description type" # TODO: error handling
      return
    end
    { id: "#{schema}/#{d_type}", schemaUri: "#{schema}/#{type_pid}" }
  end

  def get_organisation_role(pid)
    schema = "https://vocabulary.raid.org/organisation.role.schema"
    organisation_roles_pid = "359"
    organisation_roles_map = {
      "lead-research-organisation": "182",
      contractor: "185",
      "other-organisation": "188",
      "other-research-organisation": "183",
      "partner-organisation": "184"
    }
    o_role = organisation_roles_map[pid.to_sym]
    if o_role.nil?
      p "Unpermitted organisation role" # TODO: error handling
      return
    end
    { id: "#{schema}/#{o_role}", schemaUri: "#{schema}/#{organisation_roles_pid}" }
  end

  def get_contributor_position(pid)
    schema = "https://vocabulary.raid.org/contributor.position.schema"
    contributor_position_pid = "305"
    contributor_positions_map = {
      "principal-investigator": "307",
      "co-investigator": "308",
      "other-participant": "311"
    }
    c_position = contributor_positions_map[pid.to_sym]
    if c_position.nil?
      p "Unpermitted contributor position" # TODO: error handling
      return
    end
    { id: "#{schema}/#{c_position}", schemaUri: "#{schema}/#{contributor_position_pid}" }
  end
end
