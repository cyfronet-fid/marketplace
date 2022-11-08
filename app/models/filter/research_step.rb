# frozen_string_literal: true

class Filter::ResearchStep < Filter::AncestryMultiselect
  def initialize(params = {})
    super(
      params: params.fetch(:params, {}),
      field_name: "research_steps",
      title: "Research steps",
      model: Vocabulary::ResearchStep,
      joining_model: ServiceVocabulary,
      model_type: "Vocabulary::ResearchStep",
      index: "research_steps",
      search: true
    )
  end
end
