# frozen_string_literal: true

require "rails_helper"
require_relative "publishable"

RSpec.describe Provider, :backend, type: :model do
  it_behaves_like "publishable"

  describe "pid" do
    let(:provider) { build(:provider) }

    context "when pid is nil" do
      before { provider.pid = nil }

      it "assigns a generated pid" do
        expect { provider.valid? }.to change(provider, :pid).from(nil).to(be_present)
      end
    end

    context "when pid is blank" do
      before { provider.pid = "  " }

      it "assigns a generated pid" do
        expect { provider.valid? }.to change(provider, :pid).from("  ").to(be_present)
      end
    end

    context "when pid is nil and validations are skipped" do
      before do
        provider.pid = nil
        provider.save(validate: false)
      end

      it "persists a generated pid" do
        expect(provider.reload.pid).to be_present
      end
    end

    context "when pid is blank and validations are skipped" do
      before do
        provider.pid = "  "
        provider.save(validate: false)
      end

      it "persists a generated pid" do
        expect(provider.reload.pid).to be_present
      end
    end

    context "when pid is present" do
      let(:provider) { build(:provider, pid: "custom-pid") }

      it "keeps the given pid" do
        expect { provider.valid? }.not_to change(provider, :pid).from("custom-pid")
      end
    end

    context "when pid is already taken by another provider" do
      let(:provider) { build(:provider, pid: "taken-pid") }

      before { create(:provider, pid: "taken-pid") }

      it "is invalid" do
        expect(provider).not_to be_valid
      end

      it "reports the pid as taken" do
        provider.valid?
        expect(provider.errors[:pid]).to include("has already been taken")
      end

      it "is rejected by the database when validations are skipped" do
        expect { provider.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end

  describe "validations" do
    subject { create(:provider) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:legal_statuses) }
    it { is_expected.to have_many(:services) }
    it { is_expected.to have_many(:service_providers).dependent(:destroy) }
    it { is_expected.to have_many(:categorizations) }
    it { is_expected.to have_many(:categories) }
    it { is_expected.to have_many(:provider_vocabularies).dependent(:destroy) }

    context "when contacts step is validated" do
      subject { build(:provider, current_step: "contacts") }

      it { is_expected.to validate_presence_of(:public_contact_emails) }

      it "rejects invalid public contact emails" do
        subject.public_contact_emails = %w[valid@example.org invalid]

        expect(subject).not_to be_valid
        expect(subject.errors[:public_contact_emails]).to include("invalid is not a valid email")
      end
    end
  end

  context "OMS validations" do
    subject { build(:provider, omses: build_list(:provider_group_oms, 2)) }

    it { is_expected.to have_many(:omses) }
  end
end
