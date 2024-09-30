# frozen_string_literal: true

module RaidProjectHelper
  def set_contributor_roles_options
    {
      conceptualization: "conceptualization",
      "data curation": "data-curation",
      "formal analysis": "formal-analysis",
      "funding acquisition": "funding-acquisition",
      investigation: "investigation",
      methodology: "methodology",
      "project administration": "project-administration",
      resources: "resources",
      software: "software",
      supervision: "supervision",
      validation: "validation",
      visualization: "visualization",
      "writing original draft": "writing-original-draft",
      "writing review editing": "writing-review-editing"
    }.freeze
  end

  def set_contributor_positions
    {
      "Principal investigator": "principal-investigator",
      "Co-investigator": "co-investigator",
      "Other participant": "other-participant"
    }.freeze
  end

  def set_organisation_roles
    {
      "Lead research organisation": "lead-research-organisation",
      Contractor: "contractor",
      "Other organisation": "other_organisation",
      "Other research organisation": "Other_research_organisation",
      "Partner organisation": "partner_organisation"
    }.freeze
  end

  def humanize_role(role)
    role.gsub("-", " ")
  end

  def display_roles(roles)
    roles.map! { |role| humanize_role(role) }
    roles.join(", ")
  end

  def render_alternative_description_fields(form)
    render "raid_project/steps/alternative_description_fields", alternative_description_f: form
  end

  def render_alternative_title_fields(form)
    render "raid_project/steps/alternative_title_fields", alternative_title_f: form
  end

  def render_contributor_fields(form)
    render "raid_project/steps/contributor_fields", contributor_f: form
  end

  def render_organisation_fields(form)
    render "raid_project/steps/organisation_fields", organisation_f: form
  end

  def render_next_step(step_id, raid_project)
    render "/raid_project/steps/#{step_id}", raid_project: raid_project, show_recaptcha: true
  end

  def wizard_title
    session[:wizard_action] == "create" ? "Create new RAiD Project" : "Update RAiD Project"
  end

  def language_name(code)
    Raid::Language.get(code).english_name
  end
end
