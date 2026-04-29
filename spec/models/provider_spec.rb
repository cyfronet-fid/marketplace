# frozen_string_literal: true

require "rails_helper"
require_relative "publishable"

RSpec.describe Provider, type: :model, backend: true do
  include_examples "publishable"

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:legal_statuses) }
    it { should have_many(:services) }
    it { should have_many(:service_providers).dependent(:destroy) }
    it { should have_many(:categorizations) }
    it { should have_many(:categories) }
    it { should have_many(:provider_vocabularies).dependent(:destroy) }

    subject { create(:provider) }

    context "when contacts step is validated" do
      subject { build(:provider, current_step: "contacts") }

      it { should validate_presence_of(:public_contact_emails) }

      it "rejects invalid public contact emails" do
        subject.public_contact_emails = %w[valid@example.org invalid]

        expect(subject).not_to be_valid
        expect(subject.errors[:public_contact_emails]).to include("invalid is not a valid email")
      end
    end
  end

  context "OMS validations" do
    subject { build(:provider, omses: build_list(:provider_group_oms, 2)) }
    it { should have_many(:omses) }
  end
end
