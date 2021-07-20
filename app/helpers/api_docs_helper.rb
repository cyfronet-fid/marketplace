# frozen_string_literal: true

module ApiDocsHelper
  def api_wiki_subsections
    %i[introduction basic_information integration_methods oms_configuration access_model project_item_workflows]
  end

  def humanized_subsection(subsection)
    subsection.to_s.humanize
  end

  def next_subsection(current_subsection)
    api_wiki_subsections[api_wiki_subsections.index(current_subsection) + 1]
  end
end
