# frozen_string_literal: true

module Deserializable
  extend ActiveSupport::Concern

  class_methods do
    def translate_incoming_json(obj)
      titles = parse_titles(obj["title"])
      main_title, alternative_titles = titles
      if obj["description"]
        main_description, alternative_descriptions = parse_descriptions(obj["description"])
      else
        main_description = nil
        alternative_descriptions = {}
      end
      contributors = obj["contributor"].map { |contributor| parse_contributor(contributor) }
      contributors_hash = {}
      contributors.each_with_index { |c, i| contributors_hash[i] = c }
      if obj["organisation"]
        organisations = obj["organisation"].map { |organisation| parse_organisation(organisation) }
      else
        organisations = []
      end
      organisations_hash = {}
      organisations.each_with_index { |o, i| organisations_hash[i] = o }

      {
        pid: get_id(obj["identifier"]["id"]),
        start_date: obj["date"]["startDate"],
        end_date: obj["date"]["endDate"],
        main_title_attributes: main_title,
        alternative_titles_attributes: alternative_titles || {},
        main_description_attributes: main_description || {},
        alternative_descriptions_attributes: alternative_descriptions,
        contributors_attributes: contributors_hash,
        raid_access_attributes: parse_access(obj["access"]),
        raid_organisations_attributes: organisations_hash,
        identifier: obj["identifier"]
      }
    end

    private

    def parse_organisation_role(role)
      role_id = get_meaningfull_item(role["id"])
      organisation_roles_map = {
        "182": "lead-research-organisation",
        "185": "contractor",
        "188": "other-organisation",
        "183": "other-research-organisation",
        "184": "partner-organisation"
      }
      { pid: organisation_roles_map[role_id.to_sym], start_date: role["startDate"], end_date: role["endDate"] }
    end

    def parse_organisation(organisation)
      pid = organisation["id"]
      name = Raid::Ror.find_by(pid: pid).name
      { pid: pid, name: name, position_attributes: parse_organisation_role(organisation["role"][0]) }
    end

    def parse_position(position)
      position_id = get_meaningfull_item(position["id"])
      contributor_positions_map = {
        "307": "principal-investigator",
        "308": "co-investigator",
        "311": "other-participant"
      }
      {
        pid: contributor_positions_map[position_id.to_sym],
        start_date: position["startDate"],
        end_date: position["endDate"]
      }
    end

    def parse_contributor(contributor)
      {
        pid: get_meaningfull_item(contributor["id"]),
        pid_type: "orcid",
        leader: contributor["leader"],
        contact: contributor["contact"],
        roles: contributor["role"].map { |role| get_meaningfull_item(role["id"]) },
        position_attributes: parse_position(contributor["position"][0])
      }
    end

    def parse_titles(titles)
      parsed_titles = titles.map { |title| parse_title(title) }
      primary = nil
      alternatives_list = []
      parsed_titles.each do |title|
        if title[:type] == "primary"
          primary = title
        else
          alternatives_list.append(title)
        end
      end
      if alternatives_list.empty?
        alternatives = {}
      else
        alternatives = alternatives_list.map.with_index { |t, _i| { i: t["body"] } }
      end
      [primary[:body], alternatives]
    end

    def parse_title(title)
      {
        type: get_title_type(title["type"]["id"]),
        body: {
          text: title["text"],
          language: title["language"]["id"],
          start_date: title["startDate"],
          end_date: title["endDate"]
        }
      }
    end

    def parse_descriptions(descriptions)
      parsed_descriptions = descriptions.map { |description| parse_description(description) }

      primary = nil
      alternatives_list = []
      parsed_descriptions.each do |description|
        if description[:type] == "primary"
          primary = description[:body]
        else
          alternatives_list.append(description)
        end
      end
      if alternatives_list.empty?
        alternatives = {}
      else
        alternatives = alternatives_list.map.with_index { |d, i| { i.to_s => d[:body] } }
      end
      [primary, alternatives]
    end

    def parse_description(description)
      description_type = get_description_type(description["type"]["id"])
      {
        type: description_type,
        body: {
          text: description["text"],
          language: description["language"]["id"],
          description_type: description_type
        }
      }
    end

    def get_description_type(description_type)
      description_type_map = { "318": "primary", "319": "alternative" }
      type = get_meaningfull_item(description_type)
      d_type = description_type_map[type.to_sym]
      if d_type.nil?
        p "Unpermitted description type #{description_type}" # TODO: error handling
        return
      end
      d_type
    end

    def get_title_type(title_type)
      type = get_meaningfull_item(title_type)
      title_type_map = { "5": "primary", "4": "alternative" }
      t_type = title_type_map[type.to_sym]
      if t_type.nil?
        p "Unpermitted title type" # TODO: error handling
        return
      end
      t_type
    end

    def parse_access(access)
      type = get_meaningfull_item(access["type"]["id"])
      access_type_map = { c_abf2: "open", c_f1cf: "embargoed" }
      a_type = access_type_map[type.to_sym]
      {
        access_type: a_type,
        statement_text: access["statement"]["text"],
        statement_lang: access["statement"]["language"]["id"],
        embargo_expiry: access["embargoExpiry"]
      }
    end

    def get_meaningfull_item(value)
      value.split("/")[-1]
    end

    def get_id(str)
      splited = str.split("/")
      "#{splited[-2]}/#{splited[-1]}"
    end
  end
end
