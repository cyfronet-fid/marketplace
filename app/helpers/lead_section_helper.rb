# frozen_string_literal: true

module LeadSectionHelper
  def render_sections(section)
    sec = LeadSection.find_by(slug: section)
    if sec
      render "leads/section", section: sec
    else
      render "leads/error", slug: section if policy(LeadSection).error?
    end
  end
end
