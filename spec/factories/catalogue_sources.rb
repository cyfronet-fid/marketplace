# frozen_string_literal: true

FactoryBot.define do
  factory :catalogue_source do
    source_type { CatalogueSource.source_types.keys.sample }
    sequence(:eid) { |n| n }

    factory :eosc_registry_catalogue_source do
      source_type { :eosc_registry }
    end
  end
end
