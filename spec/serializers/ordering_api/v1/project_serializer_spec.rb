# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderingApi::V1::ProjectSerializer do
  it "properly serializes a project" do
    project = create(:project, user: build(:user), project_items: build_list(:project_item, 2))

    serialized = described_class.new(project).as_json
    expected = {
      id: project.id,
      owner: {
        name: project.user.full_name,
        email: project.user.email,
      },
      project_items: project.project_items.pluck(:iid),
      attributes: {
        name: project.name,
        customer_typology: project.customer_typology,
        organization: project.organization,
        department: project.department,
        department_webpage: project.webpage,
        scientific_domains: project.scientific_domains.pluck(:name),
        country: project.country_of_origin.name,
        collaboration_countries: project.countries_of_partnership&.map(&:name),
        user_group_name: project.user_group_name
      }
    }

    expect(serialized).to eq(expected)
  end

  it "properly serializes an empty project" do
    project = Project.new(
      user: build(:user)
    )

    serialized = described_class.new(project).as_json
    expected = {
      id: project.id,
      owner: {
        name: project.user.full_name,
        email: project.user.email,
      },
      project_items: [],
      attributes: {
        name: nil,
        customer_typology: nil,
        organization: nil,
        department: nil,
        department_webpage: nil,
        scientific_domains: [],
        country: nil,
        collaboration_countries: [],
        user_group_name: nil
      }
    }

    expect(serialized).to eq(expected)
  end
end
