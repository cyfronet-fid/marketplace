# frozen_string_literal: true

class Api::V1::Raid::RaidWizardSerializer < ActiveModel::Serializer
    attributes  :start_date,
                :end_date, 
                :main_title, 
                :main_description, 
                :alternative_titles, 
                :alternative_descriptions,
                :contributors,
                :raid_organisations,
                :raid_access
  end
