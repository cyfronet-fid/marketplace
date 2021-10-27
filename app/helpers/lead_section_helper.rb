# frozen_string_literal: true

module LeadSectionHelper
  def render_sections(section)
    sec = LeadSection.find_by(slug: section)
    if sec
      render "leads/section", section: sec
    elsif policy(LeadSection).error?
      render "leads/error", slug: section
    end
  end
end
