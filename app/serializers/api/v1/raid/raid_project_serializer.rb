class Api::V1::Raid::RaidProjectSerializer < ActiveModel::Serializer
  attribute :date 
  attribute :title 
  attribute :description, if: -> { object.main_description.present? }
  attribute :organisation, if: -> { object.raid_organisations.present? }
  attribute :contributor

  def date
    {
      startDate: object.start_date, 
      endDate: object.end_date
    }
  end

  def contributor
    contributors = []
    object.contributors.each do |c|
      contributors.append(serialize_contributor(c))
    end
    contributors
  end

  def serialize_contributor(c)
    c_roles = []
    id_schema = "https://#{c.pid_type.downcase}.org/"
    c.roles.each do |role|
      r = { schemaUri: "https://credit.niso.org/", id: "https://credit.niso.org/contributor-roles/#{role}/"}
      c_roles.append(r)
    end
    
    {
      id: "#{id_schema}#{c.pid}",
      schemaUri: id_schema,
      position: [serialize_position(c.position.pid, "contributor", "position")],
      role: c_roles,
      leader: c.leader,
      contact: c.contact
  }
end

  def description
    descriptions = []
    descriptions.append(serialize_description(object.main_description))
    object.alternative_descriptions.each do |d|
      descriptions.append(serialize_description(d))
    end
    descriptions 
  end

  def organisation
    organisations = []
    object.raid_organisations.each do |o|
      organisations.append(serialize_organisation(o))
    end
    organisations
  end

  def serialize_organisation(o)
    {
      id: o.pid,
      schemaUri: "https://ror.org/",
      role: [serialize_position(o.position.pid, "organisation", "role")]
  }
end

def serialize_position(pid, obj, _type)  
  {
    schemaUri: "https://github.com/au-research/raid-metadata/tree/main/scheme/#{obj}/#{_type}/v1/",
    id: "https://github.com/au-research/raid-metadata/blob/main/scheme/#{obj}/#{_type}/v1/#{pid}.json",
    startDate: "2024-03-18",
    endDate: "2024-03-30"
  }
end


  def title
    titles = []
    titles.append(serialize_title(object.main_title))
    object.alternative_titles.each do |t|
      titles.append(serialize_title(t))
    end
    titles
  end

def serialize_title(t)
  {
    text: t.text,
    type: {
        id: "https://github.com/au-research/raid-metadata/blob/main/scheme/title/type/v1/#{t.title_type}.json",
        schemaUri: "https://github.com/au-research/raid-metadata/tree/main/scheme/title/type/v1/"
    },
    startDate: t.start_date,
    endDate: t.end_date,
    language: {
        id: t.language,
        schemaUri: "https://iso639-3.sil.org"
    }
  }
end

def serialize_description(d)
  {
    text: d.text,
    type: {
      id: "https://github.com/au-research/raid-metadata/blob/main/scheme/description/type/v1/#{d.description_type}.json",
      schemaUri: "https://github.com/au-research/raid-metadata/tree/main/scheme/description/type/v1/"
    },
    language: {
        id: d.language,
        schemaUri: "https://iso639-3.sil.org"
    }
  }
end
  
end