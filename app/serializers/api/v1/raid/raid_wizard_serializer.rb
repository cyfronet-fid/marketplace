# frozen_string_literal: true

class Api::V1::Raid::RaidWizardSerializer < ActiveModel::Serializer
  attributes :start_date, :end_date, :contributors, :raid_organisations, :raid_access
  attribute :main_title, key: :main_title_attributes
  attribute :main_description, key: :main_description_attributes
  attribute :alternative_titles, key: :alternative_titles_attributes
  attribute :alternative_descriptions, key: :alternative_descriptions_attributes
end
