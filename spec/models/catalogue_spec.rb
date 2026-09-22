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
end
