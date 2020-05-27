# frozen_string_literal: true

require "rails_helper"

RSpec.describe Project do
  subject { create(:project, name: "New Project") }

  it { should belong_to(:user) }
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:customer_typology) }
  it { should validate_presence_of(:reason_for_access) }
  it { should validate_presence_of(:email) }
  it { should have_many(:project_items) }
  it { should validate_presence_of(:status) }
  it { should validate_length_of(:department).is_at_most(255) }
  it { should validate_length_of(:webpage).is_at_most(255) }
  it { should validate_length_of(:name).is_at_most(255) }
  it { should validate_length_of(:organization).is_at_most(255) }
  it { should_not allow_value("blah").for(:email) }

  describe "#department" do
    before { subject.department = "a" *256 }
    it { should_not be_valid }
  end

  describe "#webpage" do
    before { subject.webpage = "a" *256 }
    it { should_not be_valid }
  end

  describe "#organization" do
    before { subject.organization = "a" *256 }
    it { should_not be_valid }
  end

  describe "#name" do
    before { subject.name = "a" *256 }
    it { should_not be_valid }
  end


  describe "single user" do
    subject { build(:project, customer_typology: "single_user") }

    it { is_expected.to validate_presence_of(:organization) }
    it { is_expected.to validate_presence_of(:webpage) }
  end

  describe "research typology" do
    subject { build(:project, customer_typology: "research") }

    it { is_expected.to validate_presence_of(:user_group_name) }
    it { is_expected.to validate_presence_of(:organization) }
    it { is_expected.to validate_presence_of(:webpage) }

    describe "#organization" do
      before { subject.organization = "a" *256 }
      it { should_not be_valid }
    end
  end

  describe "project typology" do
    subject { build(:project, customer_typology: "project") }

    it { is_expected.to validate_presence_of(:project_name) }
    it { is_expected.to validate_presence_of(:project_website_url) }

    describe "#project_website_url" do
      before { subject.project_website_url = "a" * 256 }
      it { should_not be_valid }
    end
  end

  describe "private_company typology" do
    subject { build(:project, customer_typology: "private_company") }

    it { is_expected.to validate_presence_of(:company_name) }
    it { is_expected.to validate_presence_of(:company_website_url) }

    describe "#company_name" do
      before { subject.company_name = "a" *256 }
      it { should_not be_valid }
    end

    describe "#company_website_url" do
      before { subject.company_website_url = "a" *256 }
      it { should_not be_valid }
    end
  end

  describe "#countries_of_partnership" do
    subject { create(:project, countries_of_partnership: [ "PL", "N/E" ]) }

    it "uses Country model for serialization" do
      expect(subject.countries_of_partnership).
        to contain_exactly(Country.for("PL"), Country.for("N/E"))
    end
  end

  describe "#country_of_origin" do
    subject { create(:project, country_of_origin: "PL") }

    it "uses Country model for serialization" do
      expect(subject.country_of_origin).to eq(Country.for("PL"))
    end
  end

  context "#jira" do
    it "should validate presence of issue_id & issue_key" do
      expect(build(:project, issue_status: :jira_require_migration, issue_id: nil, issue_key: nil)).to be_valid
      expect(build(:project, issue_status: :jira_deleted, issue_id: nil, issue_key: nil)).to_not be_valid
      expect(build(:project, issue_status: :jira_uninitialized, issue_id: nil, issue_key: nil)).to be_valid
      expect(build(:project, issue_status: :jira_errored, issue_id: nil, issue_key: nil)).to be_valid
      expect(build(:project, issue_status: :jira_active, issue_id: nil, issue_key: nil)).to_not be_valid

      expect(build(:project, issue_status: :jira_active,
                   issue_id: 1, issue_key: "MP-1")).to be_valid
      expect(build(:project, issue_status: :jira_deleted,
                   issue_id: 1, issue_key: "MP-1")).to be_valid
    end
  end
end
