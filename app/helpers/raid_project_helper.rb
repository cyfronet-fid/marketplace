# frozen_string_literal: true

module RaidProjectHelper
    def set_contributor_roles_options
        { 
            "conceptualization": "conceptualization",
            "data curation": "data-curation",
            "formal analysis": "formal-analysis", 
            "funding acquisition": "funding-acquisition",
            "investigation": "investigation",
            "methodology": "methodology",
            "project administration": "project-administration",
            "resources": "resources",
            "software": "software",
            "supervision": "supervision",
            "validation": "validation",
            "visualization": "visualization",
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
            "Contractor": "contractor",
            "Other organisation": "other_organisation",
            "Other research organisation": "Other_research_organisation",
            "Partner organisation": "partner_organisation"
        }.freeze
    end
end