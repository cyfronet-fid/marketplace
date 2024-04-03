

module RaidProjectContributorRoleHelper
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
end