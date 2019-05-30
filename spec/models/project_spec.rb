# frozen_string_literal: true

require "rails_helper"

RSpec.describe Project do
  subject { create(:project, name: "New Project") }

  it { should belong_to(:user) }
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:customer_typology) }
  it { should validate_presence_of(:reason_for_access) }
  it { should have_many(:project_items) }

  describe "research typology" do
    subject { build(:project, customer_typology: "research") }

    it { is_expected.to validate_presence_of(:user_group_name) }
  end

  describe "project typology" do
    subject { build(:project, customer_typology: "project") }

    it { is_expected.to validate_presence_of(:project_name) }
    it { is_expected.to validate_presence_of(:project_website_url) }
  end

  describe "private_company typology" do
    subject { build(:project, customer_typology: "private_company") }

    it { is_expected.to validate_presence_of(:company_name) }
    it { is_expected.to validate_presence_of(:company_website_url) }
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
