# frozen_string_literal: true

class Filter::MarketplaceLocation < Filter::AncestryMultiselect
  def initialize(params = {})
    super(
      params: params.fetch(:params, {}),
      field_name: "marketplace_locations",
      title: "Marketplace Locations",
      model: Vocabulary::MarketplaceLocation,
      joining_model: ServiceVocabulary,
      model_type: "Vocabulary::MarketplaceLocation",
      index: "marketplace_locations",
      search: true
    )
  end
end
