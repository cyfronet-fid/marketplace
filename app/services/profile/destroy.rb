# frozen_string_literal: true

class Profile::Destroy
  def initialize(profile)
    @profile = profile
  end

  def call
    @profile.update(categories: [], research_areas: [],
                    categories_updates: false, research_areas_updates: false)
  end
end
