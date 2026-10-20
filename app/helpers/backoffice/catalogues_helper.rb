# frozen_string_literal: true

module Backoffice::CataloguesHelper
  def cant_edit_catalogue?(attribute)
    !policy([:backoffice, @catalogue]).permitted_attributes.include?(attribute)
  end

  # pl's catalogue form views call it without the question mark.
  def cant_edit_catalogue(attribute)
    cant_edit_catalogue?(attribute)
  end
end
