# frozen_string_literal: true

require "rails_helper"
require_relative "messageable"
require_relative "publishable"

RSpec.describe Project, backend: true do
  subject { create(:project, name: "New Project") }

  it { should belong_to(:user) }
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:customer_typology) }
  xit { should validate_presence_of(:email), skip: "Disabled field" }
  it { should have_many(:project_items) }
  it { should validate_presence_of(:status) }
  it { should validate_length_of(:department).is_at_most(255) }
  xit { should validate_length_of(:webpage).is_at_most(255), skip: "Disabled field" }
  it { should validate_length_of(:name).is_at_most(255) }
  it { should validate_length_of(:organization).is_at_most(255) }
  xit { should_not allow_value("blah").for(:email), skip: "Disabled field" }

  include_examples "messageable"
  include_examples "publishable"

  describe "#department" do
    before { subject.department = "a" * 256 }
    it { should_not be_valid }
  end

  describe "#webpage" do
    before { subject.webpage = "a" * 256 }
    xit { should_not be_valid, skip: "Disabled field" }
  end

  describe "#organization" do
    before { subject.organization = "a" * 256 }
    it { should_not be_valid }
  end

  describe "#name" do
    before { subject.name = "a" * 256 }
    it { should_not be_valid }
  end

  describe "single user" do
    subject { build(:project, customer_typology: "single_user") }

    xit { is_expected.to validate_presence_of(:organization), skip: "Disabled field" }
    xit { is_expected.to validate_presence_of(:webpage), skip: "Disabled field" }
  end

  describe "research typology" do
    subject { build(:project, customer_typology: "research") }

    it { is_expected.to validate_presence_of(:user_group_name) }
    xit { is_expected.to validate_presence_of(:organization), skip: "Disabled field" }
    xit { is_expected.to validate_presence_of(:webpage), skip: "Disabled field" }

    describe "#organization" do
      before { subject.organization = "a" * 256 }
      xit { should_not be_valid, skip: "Disabled field" }
    end
  end

  describe "project typology" do
    subject { build(:project, customer_typology: "project") }

    it { is_expected.to validate_presence_of(:project_owner) }

    describe "#project_website_url" do
      before { subject.project_website_url = "a" * 256 }
      it { should_not be_valid }
    end
  end

  describe "private_company typology" do
    subject { build(:project, customer_typology: "private_company") }

    it { is_expected.to validate_presence_of(:company_name) }
    xit { is_expected.to validate_presence_of(:company_website_url), skip: "Disabled field" }

    describe "#company_name" do
      before { subject.company_name = "a" * 256 }
      it { should_not be_valid }
    end

    describe "#company_website_url" do
      before { subject.company_website_url = "a" * 256 }
      it { should_not be_valid }
    end
  end

  describe "#countries_of_partnership" do
    subject { create(:project, countries_of_partnership: %w[PL N/E]) }

    it "uses Country model for serialization" do
      expect(subject.countries_of_partnership).to contain_exactly(Country.for("PL"), Country.for("N/E"))
    end
  end

  describe "#country_of_origin" do
    subject { create(:project, country_of_origin: "PL") }

    it "uses Country model for serialization" do
      expect(subject.country_of_origin).to eq(Country.for("PL"))
    end
  end

  describe "#items_have_new_messages?" do
    it "returns true if any of the project items messages are new" do
      project_item1 = create(:project_item, project: subject)
      project_item2 = create(:project_item, project: subject, conversation_last_seen: Time.now)
      create(:provider_message, messageable: project_item1)
      create(:provider_message, messageable: project_item1)
      create(:provider_message, messageable: project_item2)
      subject.reload

      expect(subject.items_have_new_messages?).to be_truthy
    end

    it "returns false if all of the project items messages are viewed" do
      project_item1 = create(:project_item, project: subject, conversation_last_seen: Time.now)
      project_item2 = create(:project_item, project: subject, conversation_last_seen: Time.now)
      create(:provider_message, messageable: project_item1)
      create(:provider_message, messageable: project_item1)
      create(:provider_message, messageable: project_item2)
      subject.update(conversation_last_seen: Time.now)

      expect(subject.items_have_new_messages?).to be_falsey
    end

    it "returns false if the project doesn't have any project items" do
      expect(subject.items_have_new_messages?).to be_falsey
    end

    it "returns false if none of the project's project items have any messages" do
      create(:project_item, project: subject)
      create(:project_item, project: subject)
      subject.reload

      expect(subject.items_have_new_messages?).to be_falsey
    end
  end

  context "#jira" do
    it "should validate presence of issue_id & issue_key" do
      expect(build(:project, issue_status: :jira_require_migration, issue_id: nil, issue_key: nil)).to be_valid
      expect(build(:project, issue_status: :jira_deleted, issue_id: nil, issue_key: nil)).to_not be_valid
      expect(build(:project, issue_status: :jira_uninitialized, issue_id: nil, issue_key: nil)).to be_valid
      expect(build(:project, issue_status: :jira_errored, issue_id: nil, issue_key: nil)).to be_valid
      expect(build(:project, issue_status: :jira_active, issue_id: nil, issue_key: nil)).to_not be_valid

      expect(build(:project, issue_status: :jira_active, issue_id: 1, issue_key: "MP-1")).to be_valid
      expect(build(:project, issue_status: :jira_deleted, issue_id: 1, issue_key: "MP-1")).to be_valid
    end
  end

  context "eventable" do
    describe "#eventable_identity" do
      it "has proper identity" do
        expect(subject.eventable_identity).to eq({ project_id: subject.id })
      end
    end

    describe "#eventable_omses" do
      it "handles empty project" do
        expect(subject.eventable_omses).to eq([])
      end

      context "with project_items with overlapping primary_oms" do
        before do
          @oms1 = create(:oms)
          @oms2 = create(:oms)
          create(:project_item, project: subject, offer: create(:offer, primary_oms: @oms1))
          create(:project_item, project: subject, offer: create(:offer, primary_oms: @oms2))
          create(:project_item, project: subject, offer: create(:offer, primary_oms: @oms2))
          subject.reload
        end

        it "merges the OMSes" do
          expect(subject.eventable_omses).to contain_exactly(@oms1, @oms2)
        end
      end
    end

    it "should create an event on create" do
      project = create(:project)
      expect(Event.count).to eq(1)
      expect(Event.first.eventable).to eq(project)
      expect(Event.first.action).to eq("create")
    end
  end
end
