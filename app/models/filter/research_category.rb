# frozen_string_literal: true

class Filter::ResearchCategory < Filter::AncestryMultiselect
  def initialize(params = {})
    super(
      params: params.fetch(:params, {}),
      field_name: "research_categories",
      title: "Research categories",
      model: Vocabulary::ResearchCategory,
      joining_model: ServiceVocabulary,
      model_type: "Vocabulary::ResearchCategory",
      index: "research_categories",
      search: true
    )
  end
end
