# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::ProjectSerializer, backend: true do
  it "properly serializes a project" do
    project = create(:project, user: build(:user), project_items: build_list(:project_item, 2))

    serialized = described_class.new(project).as_json
    expected = {
      id: project.id,
      owner: {
        uid: project.user.uid,
        name: project.user.full_name,
        email: project.user.email,
        first_name: project.user.first_name,
        last_name: project.user.last_name
      },
      project_items: project.project_items.pluck(:iid),
      attributes: {
        name: project.name,
        customer_typology: project.customer_typology,
        organization: project.organization,
        department: project.department,
        department_webpage: project.webpage,
        scientific_domains: project.scientific_domains.pluck(:name),
        country: project.country_of_origin.iso_short_name,
        collaboration_countries: project.countries_of_partnership&.map(&:iso_short_name),
        user_group_name: project.user_group_name
      }
    }

    expect(serialized).to eq(expected)
  end

  it "properly serializes an empty project" do
    project = Project.new(user: build(:user))

    serialized = described_class.new(project).as_json
    expected = {
      id: project.id,
      owner: {
        uid: project.user.uid,
        name: project.user.full_name,
        email: project.user.email,
        first_name: project.user.first_name,
        last_name: project.user.last_name
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
