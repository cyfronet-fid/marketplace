# frozen_string_literal: true

module Backoffice::ProvidersHelper
  def cant_edit(attribute)
    policy([:backoffice, @provider]).permitted_attributes.exclude?(attribute)
  end
end
