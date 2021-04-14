# frozen_string_literal: true

module FavouriteHelper
  def favourite?(services, slug)
    services.any? { |s| s.slug == slug }
  end
end
