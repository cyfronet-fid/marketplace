# frozen_string_literal: true

require "image_processing/vips"

FactoryBot.define do
  factory :catalogue do
    sequence(:name) { |n| "catalogue #{n}" }
    sequence(:pid) { |n| "catalogue-pid#{n}" }
    sequence(:abbreviation) { |n| "catalogue #{n}" }
    sequence(:scope) { "Scope" }
    sequence(:end_of_life) { "EOU" }
    sequence(:inclusion_criteria) { "https://website.com" }
    sequence(:validation_process) { "https://website.com" }
    sequence(:website) { "https://website.com" }
    sequence(:legal_entity) { |_n| true }
    sequence(:description) { |n| "description #{n}" }
    sequence(:street_name_and_number) { |n| "Saint St. #{n}" }
    sequence(:postal_code) { |n| "#{n}#{n + 1}-#{n + 2}#{n + 3}#{n + 4}" }
    sequence(:city) { |n| "city #{n}" }
    sequence(:country) { |_n| "N/E" }
    sequence(:status) { :published }

    public_contacts { [build(:public_contact)] }
    main_contact { build(:main_contact) }

    sources { [build(:catalogue_source, eid: pid)] }
    data_administrators { [build(:data_administrator)] }

    after(:build) do |catalogue|
      image =
        Vips::Image.new_from_buffer(
          Base64.decode64(
            "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"
          ),
          ""
        )
      logo = StringIO.new
      logo.write(image.write_to_buffer(".png"))
      logo.rewind

      catalogue.logo.attach(io: logo, filename: catalogue.pid + ".png", content_type: "image/png")
    end
  end
end
