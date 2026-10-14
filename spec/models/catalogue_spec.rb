# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalogue, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:service_catalogues).dependent(:destroy) }

    it { is_expected.to have_many(:services).through(:service_catalogues) }

    it { is_expected.to have_many(:provider_catalogues).dependent(:destroy) }

    it { is_expected.to have_many(:providers).through(:provider_catalogues) }

    it { is_expected.to have_many(:catalogue_scientific_domains).dependent(:destroy) }

    it { is_expected.to have_many(:scientific_domains).through(:catalogue_scientific_domains) }

    it { is_expected.to have_one(:main_contact).dependent(:destroy) }

    it { is_expected.to have_many(:public_contacts).dependent(:destroy) }

    it { is_expected.to have_many(:link_multimedia_urls).dependent(:destroy) }

    it { is_expected.to have_many(:catalogue_vocabularies).dependent(:destroy) }

    it { is_expected.to have_many(:networks).through(:catalogue_vocabularies) }

    it { is_expected.to have_many(:legal_statuses).through(:catalogue_vocabularies) }

    it { is_expected.to have_many(:hosting_legal_entities).through(:catalogue_vocabularies) }

    it { is_expected.to have_many(:nodes).through(:catalogue_vocabularies) }

    it { is_expected.to have_many(:sources).class_name("CatalogueSource").dependent(:destroy) }

    it { is_expected.to belong_to(:upstream).class_name("CatalogueSource").optional }

    it { is_expected.to have_many(:catalogue_data_administrators).dependent(:destroy) }

    it { is_expected.to have_many(:data_administrators).through(:catalogue_data_administrators) }
  end

  describe "validations" do
    subject { build(:catalogue) }

    it { is_expected.to validate_presence_of(:name) }
  end

  describe "pid" do
    let(:catalogue) { build(:catalogue) }

    context "when pid is nil" do
      before { catalogue.pid = nil }

      it "assigns a generated pid" do
        expect { catalogue.valid? }.to change(catalogue, :pid).from(nil).to(be_present)
      end
    end

    context "when pid is blank" do
      before { catalogue.pid = "  " }

      it "assigns a generated pid" do
        expect { catalogue.valid? }.to change(catalogue, :pid).from("  ").to(be_present)
      end
    end

    context "when pid is nil and validations are skipped" do
      before do
        catalogue.pid = nil
        catalogue.save(validate: false)
      end

      it "persists a generated pid" do
        expect(catalogue.reload.pid).to be_present
      end
    end

    context "when pid is blank and validations are skipped" do
      before do
        catalogue.pid = "  "
        catalogue.save(validate: false)
      end

      it "persists a generated pid" do
        expect(catalogue.reload.pid).to be_present
      end
    end

    context "when pid is present" do
      let(:catalogue) { build(:catalogue, pid: "custom-pid") }

      it "keeps the given pid" do
        expect { catalogue.valid? }.not_to change(catalogue, :pid).from("custom-pid")
      end
    end

    context "when pid is already taken by another catalogue" do
      let(:catalogue) { build(:catalogue, pid: "taken-pid") }

      before { create(:catalogue, pid: "taken-pid") }

      it "is invalid" do
        expect(catalogue).not_to be_valid
      end

      it "reports the pid as taken" do
        catalogue.valid?
        expect(catalogue.errors[:pid]).to include("has already been taken")
      end

      it "is rejected by the database when validations are skipped" do
        expect { catalogue.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end

  describe "validations when not running as pl" do
    subject { build(:catalogue) }

    before { allow(Mp::Variant).to receive(:pl?).and_return(false) }

    it { is_expected.not_to validate_presence_of(:abbreviation) }

    it { is_expected.not_to validate_presence_of(:data_administrators) }
  end

  describe "validations when running as pl" do
    subject { build(:catalogue) }

    before { allow(Mp::Variant).to receive(:pl?).and_return(true) }

    it { is_expected.to validate_presence_of(:name) }

    it { is_expected.to validate_presence_of(:abbreviation) }

    it { is_expected.to validate_presence_of(:website) }

    it { is_expected.to validate_presence_of(:inclusion_criteria) }

    it { is_expected.to validate_presence_of(:end_of_life) }

    it { is_expected.to validate_presence_of(:validation_process) }

    it { is_expected.to validate_presence_of(:scope) }

    it { is_expected.to validate_presence_of(:description) }

    it { is_expected.to validate_presence_of(:street_name_and_number) }

    it { is_expected.to validate_presence_of(:postal_code) }

    it { is_expected.to validate_presence_of(:city) }

    it { is_expected.to validate_presence_of(:public_contacts) }

    it { is_expected.to validate_presence_of(:data_administrators) }
  end
end
