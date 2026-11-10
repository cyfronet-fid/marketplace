# frozen_string_literal: true

module Propagable
  extend ActiveSupport::Concern

  TYPES = {
    catalogue: "catalogue",
    provider: "provider",
    service: "service",
    datasource: "data source",
    offer: "offer",
    bundle: "bundle"
  }.freeze

  included { after_save :propagate_to_ess }

  def propagate_to_ess(propagate_offers: true)
    if public? && !destroyed?
      Ess::Add.call(self, propagable_type, propagate_offers: propagate_offers)
    else
      Ess::Delete.call(id, propagable_type)
    end
  end

  def propagable_type
    TYPES[self.class.name.downcase.to_sym]
  end
end
