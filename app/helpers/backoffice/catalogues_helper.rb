# frozen_string_literal: true

module Backoffice::CataloguesHelper
  def cant_edit_catalogue(attribute)
    !policy([:backoffice, @catalogue]).permitted_attributes.include?(attribute)
  end
end
