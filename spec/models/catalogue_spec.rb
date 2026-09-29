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
