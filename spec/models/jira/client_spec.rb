# frozen_string_literal: true

require "rails_helper"

describe Jira::Client, backend: true do
  let(:client) { Jira::Client.new }
  let(:over_255_characters) { "f" * 256 }

  it "should Issuetype when calling mp_issue_type" do
    return_val = :issue_type
    expect(client).to receive_message_chain("Issuetype.find").with(client.jira_issue_type_id).and_return(return_val)
    expect(client.mp_issue_type).to equal(return_val)
  end

  it "should find Project when calling mp_project" do
    return_val = :project
    expect(client).to receive_message_chain("Project.find").with(client.jira_project_key).and_return(return_val)
    expect(client.mp_project).to equal(return_val)
  end

  it "create_service issue should save issue with correct fields" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ROOT_URL").and_return("https://mp.edu")

    user = create(:user, first_name: "John", last_name: "Doe", uid: "uid1")
    project_item =
      create(
        :project_item,
        offer:
          create(
            :offer,
            name: "off1",
            service: create(:service, name: "s1", categories: [create(:category, name: "cat1")]),
            primary_oms: create(:oms, custom_params: { order_target: { mandatory: false } }),
            oms_params: {
              order_target: "admin@example.com"
            }
          ),
        project:
          create(
            :project,
            user: user,
            name: "My Secret Project",
            user_group_name: "New user group",
            reason_for_access: "some reason"
          ),
        properties: [
          {
            id: "id1",
            type: "input",
            label: "Data repository name",
            value: "aaaaaa",
            value_type: "string",
            description: "Type data repository name"
          },
          {
            id: "id2",
            type: "select",
            label: "Harvesting method",
            value: "OAI-PMH",
            config: {
              mode: "buttons",
              values: ["OAI-PMH", "JSON-API", "CSW 2.0", "Other"]
            },
            value_type: "string",
            description: "Choose harvesting method"
          },
          {
            id: "id3",
            type: "input",
            label: "Harvesting endpoint",
            value: "aaaaa",
            value_type: "string",
            description: "Type harvesting endpoint"
          }
        ]
      )

    expected_fields = {
      :summary => "Service order, John Doe, s1",
      :project => {
        key: "MP"
      },
      :issuetype => {
        id: 10_000
      },
      "Order reference-1" =>
        Rails.application.routes.url_helpers.project_service_url(
          project_item.project,
          project_item,
          host: "https://mp.edu"
        ),
      # "CI-EOSC-UniqueID-1" => "uid1",
      # "CI-Institution-1" => "organization 1",
      "Epic Link-1" => "MP-1",
      "CP-Platforms-1" => "",
      "CP-INeedAVoucher-1" => {
        "id" => "20004"
      },
      "CP-VoucherID-1" => "",
      "SO-1-1" => {
        "category" => "cat1",
        "service" => "s1",
        "offer" => "off1",
        "attributes" => {
          "Data repository name" => "aaaaaa",
          "Harvesting method" => "OAI-PMH",
          "Harvesting endpoint" => "aaaaa"
        }
      }.to_json,
      "SO-ServiceOrderTarget-1" => "admin@example.com",
      "SO-OfferType-1" => {
        "id" => "20005"
      }
    }

    issue = double(:Issue)
    expect(issue).to receive("save").with(fields: expected_fields).and_return(true)
    expect(client).to receive_message_chain("Issue.build").and_return(issue)

    expect(client.create_service_issue(project_item)).to be(issue)
  end

  it "create_service open access issue should save issue with correct fields" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ROOT_URL").and_return("https://mp.edu")

    user = create(:user, first_name: "John", last_name: "Doe", uid: "uid2")
    project_item =
      create(
        :project_item,
        offer:
          create(
            :open_access_offer,
            name: "off1",
            service: create(:open_access_service, name: "s1", categories: [create(:category, name: "cat1")])
          ),
        project:
          create(
            :project,
            user: user,
            name: "My Secret Project",
            user_group_name: nil,
            reason_for_access: "Some reason",
            customer_typology: "single_user"
          )
      )

    expected_fields = {
      :summary => "Service order, John Doe, s1",
      :project => {
        key: "MP"
      },
      :issuetype => {
        id: 10_000
      },
      "Order reference-1" =>
        Rails.application.routes.url_helpers.project_service_url(
          project_item.project,
          project_item,
          host: "https://mp.edu"
        ),
      "Epic Link-1" => "MP-1",
      "CP-Platforms-1" => "",
      "CP-INeedAVoucher-1" => {
        "id" => "20004"
      },
      "CP-VoucherID-1" => "",
      "SO-1-1" => { "category" => "cat1", "service" => "s1", "offer" => "off1", "attributes" => {} }.to_json,
      "SO-ServiceOrderTarget-1" => "",
      "SO-OfferType-1" => {
        "id" => "20006"
      }
    }

    issue = double(:Issue)
    expect(issue).to receive("save").with(fields: expected_fields).and_return(true)
    expect(client).to receive_message_chain("Issue.build").and_return(issue)

    expect(client.create_service_issue(project_item)).to be(issue)
  end

  it "create_service open access with voucher id" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ROOT_URL").and_return("https://mp.edu")

    user = create(:user, first_name: "John", last_name: "Doe", uid: "uid2")
    project_item =
      create(
        :project_item,
        offer:
          create(
            :open_access_offer,
            name: "off1",
            voucherable: true,
            service: create(:open_access_service, name: "s1", categories: [create(:category, name: "cat1")])
          ),
        voucher_id: "123123",
        project:
          create(
            :project,
            user: user,
            name: "My Secret Project",
            user_group_name: "New user group",
            reason_for_access: "Some reason",
            customer_typology: "single_user"
          )
      )

    expected_fields = {
      :summary => "Service order, John Doe, s1",
      :project => {
        key: "MP"
      },
      :issuetype => {
        id: 10_000
      },
      "Order reference-1" =>
        Rails.application.routes.url_helpers.project_service_url(
          project_item.project,
          project_item,
          host: "https://mp.edu"
        ),
      "Epic Link-1" => "MP-1",
      "CP-Platforms-1" => "",
      "CP-INeedAVoucher-1" => {
        "id" => "20004"
      },
      "CP-VoucherID-1" => "123123",
      "SO-1-1" => { "category" => "cat1", "service" => "s1", "offer" => "off1", "attributes" => {} }.to_json,
      "SO-ServiceOrderTarget-1" => "",
      "SO-OfferType-1" => {
        "id" => "20006"
      }
    }

    issue = double(:Issue)
    expect(issue).to receive("save").with(fields: expected_fields).and_return(true)
    expect(client).to receive_message_chain("Issue.build").and_return(issue)

    expect(client.create_service_issue(project_item)).to be(issue)
  end

  it "create_service open access requesting vouchers" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ROOT_URL").and_return("https://mp.edu")

    user = create(:user, first_name: "John", last_name: "Doe", uid: "uid2")
    project_item =
      create(
        :project_item,
        offer:
          create(
            :open_access_offer,
            name: "off1",
            voucherable: true,
            service: create(:open_access_service, name: "s1", categories: [create(:category, name: "cat1")])
          ),
        request_voucher: true,
        project:
          create(
            :project,
            user: user,
            name: "My Secret Project",
            user_group_name: "New user group",
            reason_for_access: "Some reason"
          )
      )

    expected_fields = {
      :summary => "Service order, John Doe, s1",
      :project => {
        key: "MP"
      },
      :issuetype => {
        id: 10_000
      },
      "Order reference-1" =>
        Rails.application.routes.url_helpers.project_service_url(
          project_item.project,
          project_item,
          host: "https://mp.edu"
        ),
      "Epic Link-1" => "MP-1",
      "CP-Platforms-1" => "",
      "CP-INeedAVoucher-1" => {
        "id" => "20003"
      },
      "CP-VoucherID-1" => "",
      "SO-1-1" => { "category" => "cat1", "service" => "s1", "offer" => "off1", "attributes" => {} }.to_json,
      "SO-ServiceOrderTarget-1" => "",
      "SO-OfferType-1" => {
        "id" => "20006"
      }
    }

    issue = double(:Issue)
    expect(issue).to receive("save").with(fields: expected_fields).and_return(true)
    expect(client).to receive_message_chain("Issue.build").and_return(issue)

    expect(client.create_service_issue(project_item)).to be(issue)
  end

  it "create_project_issue should save issue with correct fields" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ROOT_URL").and_return("https://mp.edu")

    user = create(:user, first_name: "John", last_name: "Doe", uid: "uid2", email: "john.doe@email.eu")
    project =
      create(
        :project,
        user: user,
        name: "My Secret Project",
        email: "project@email.com",
        user_group_name: "User Group Name 1",
        customer_typology: "research",
        reason_for_access: "some reason",
        department: "dep",
        webpage: "http://dep-wwww.pl",
        organization: "org",
        scientific_domains: [create(:scientific_domain, name: "My RA")]
      )

    expected_fields = {
      :summary => "Project, John Doe, My Secret Project",
      :project => {
        key: "MP"
      },
      :issuetype => {
        id: 10_001
      },
      "Epic Name-1" => "My Secret Project",
      "CI-Name-1" => "John",
      "CI-Surname-1" => "Doe",
      "CI-DisplayName-1" => "John Doe",
      "CI-Email-1" => "project@email.com",
      "CI-Institution-1" => "org",
      "CI-Department-1" => "dep",
      "CI-DepartmentalWebPage-1" => "http://dep-wwww.pl",
      "CI-EOSC-UniqueID-1" => "uid2",
      "CP-ScientificDiscipline-1" => "My RA",
      "CP-CustomerTypology-1" => {
        "id" => "20001"
      },
      "SO-ProjectName-1" => "My Secret Project (#{project.id})",
      "CP-UserGroupName-1" => "User Group Name 1",
      "CP-CustomerCountry-1" => project.country_of_origin.iso_short_name.to_s,
      "CP-CollaborationCountry-1" => project.countries_of_partnership.map(&:iso_short_name).join(", ").to_s
      # "CP-ReasonForAccess-1" => "some reason",
      # "CP-ProjectInformation-1" => "My Secret Project",
    }

    issue = double(:Issue)
    expect(issue).to receive("save").with(fields: expected_fields).and_return(true)
    expect(client).to receive_message_chain("Issue.build").and_return(issue)

    expect(client.create_project_issue(project)).to be(issue)
  end

  it "create_project_issue should truncate fields to 255 chars" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ROOT_URL").and_return("https://mp.edu")

    user = create(:user, first_name: "John", last_name: "Doe", uid: "uid2", email: "john.doe@email.eu")
    project =
      create(
        :project,
        user: user,
        name: "e" * 255,
        email: "project@email.com",
        user_group_name: "User Group Name 1",
        customer_typology: "research",
        reason_for_access: "some reason",
        department: "dep",
        webpage: "http://dep-wwww.pl",
        organization: "org",
        scientific_domains: [create(:scientific_domain, name: over_255_characters)],
        countries_of_partnership: Country.all
      )

    expected_fields = {
      :summary => "Project, John Doe, #{"e" * (255 - 19)}",
      :project => {
        key: "MP"
      },
      :issuetype => {
        id: 10_001
      },
      "Epic Name-1" => "e" * 255,
      "CI-Name-1" => "John",
      "CI-Surname-1" => "Doe",
      "CI-DisplayName-1" => "John Doe",
      "CI-Email-1" => "project@email.com",
      "CI-Institution-1" => "org",
      "CI-Department-1" => "dep",
      "CI-DepartmentalWebPage-1" => "http://dep-wwww.pl",
      "CI-EOSC-UniqueID-1" => "uid2",
      "CP-ScientificDiscipline-1" => over_255_characters[..254],
      "CP-CustomerTypology-1" => {
        "id" => "20001"
      },
      "SO-ProjectName-1" => "e" * 255,
      "CP-UserGroupName-1" => "User Group Name 1",
      "CP-CustomerCountry-1" => project.country_of_origin.iso_short_name.to_s,
      "CP-CollaborationCountry-1" => project.countries_of_partnership.map(&:iso_short_name).join(", ").to_s
    }

    issue = double(:Issue)
    expect(issue).to receive("save").with(fields: expected_fields).and_return(true)
    expect(client).to receive_message_chain("Issue.build").and_return(issue)

    expect(client.create_project_issue(project)).to be(issue)
  end

  it "update_project_issue should update issue with correct fields" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ROOT_URL").and_return("https://mp.edu")

    user = create(:user, first_name: "John", last_name: "Doe", uid: "uid2", email: "john.doe@email.eu")
    project =
      create(
        :project,
        user: user,
        name: "My Updated Project Name",
        email: "project@email.com",
        user_group_name: "User Group Name 1",
        customer_typology: "research",
        reason_for_access: "some reason",
        department: "dep",
        webpage: "http://dep-wwww.pl",
        organization: "org",
        issue_id: "1234",
        scientific_domains: [create(:scientific_domain, name: "My RA")]
      )

    issue = double(:Issue)
    expected_updated_fields = {
      :summary => "Project, John Doe, My Updated Project Name",
      "Epic Name-1" => "My Updated Project Name",
      "CI-Name-1" => "John",
      "CI-Surname-1" => "Doe",
      "CI-DisplayName-1" => "John Doe",
      "CI-Email-1" => "project@email.com",
      "CI-Institution-1" => "org",
      "CI-Department-1" => "dep",
      "CI-DepartmentalWebPage-1" => "http://dep-wwww.pl",
      "CI-EOSC-UniqueID-1" => "uid2",
      "CP-ScientificDiscipline-1" => "My RA",
      "CP-CustomerTypology-1" => {
        "id" => "20001"
      },
      "SO-ProjectName-1" => "My Updated Project Name (#{project.id})",
      "CP-UserGroupName-1" => "User Group Name 1",
      "CP-CustomerCountry-1" => project.country_of_origin.iso_short_name.to_s,
      "CP-CollaborationCountry-1" => project.countries_of_partnership.map(&:iso_short_name).join(", ").to_s
    }

    expect(issue).to receive("save").with(fields: expected_updated_fields).and_return(true)
    expect(client).to receive_message_chain("Issue.find").and_return(issue)
    expect(client.update_project_issue(project)).to be(issue)
  end

  it "update_project_issue should truncate fields to 255 chars" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ROOT_URL").and_return("https://mp.edu")

    user = create(:user, first_name: "John", last_name: "Doe", uid: "uid2", email: "john.doe@email.eu")
    project =
      create(
        :project,
        user: user,
        name: "e" * 255,
        email: "project@email.com",
        user_group_name: "User Group Name 1",
        customer_typology: "research",
        reason_for_access: "some reason",
        department: "dep",
        webpage: "http://dep-wwww.pl",
        organization: "org",
        issue_id: "1234",
        scientific_domains: [create(:scientific_domain, name: over_255_characters)],
        countries_of_partnership: Country.all
      )

    issue = double(:Issue)
    expected_updated_fields = {
      :summary => "Project, John Doe, #{"e" * (255 - 19)}",
      "Epic Name-1" => "e" * 255,
      "CI-Name-1" => "John",
      "CI-Surname-1" => "Doe",
      "CI-DisplayName-1" => "John Doe",
      "CI-Email-1" => "project@email.com",
      "CI-Institution-1" => "org",
      "CI-Department-1" => "dep",
      "CI-DepartmentalWebPage-1" => "http://dep-wwww.pl",
      "CI-EOSC-UniqueID-1" => "uid2",
      "CP-ScientificDiscipline-1" => over_255_characters[..254],
      "CP-CustomerTypology-1" => {
        "id" => "20001"
      },
      "SO-ProjectName-1" => "e" * 255,
      "CP-UserGroupName-1" => "User Group Name 1",
      "CP-CustomerCountry-1" => project.country_of_origin.iso_short_name.to_s,
      "CP-CollaborationCountry-1" => project.countries_of_partnership.map(&:iso_short_name).join(", ").to_s
    }

    expect(issue).to receive("save").with(fields: expected_updated_fields).and_return(true)
    expect(client).to receive_message_chain("Issue.find").and_return(issue)
    expect(client.update_project_issue(project)).to be(issue)
  end
end
