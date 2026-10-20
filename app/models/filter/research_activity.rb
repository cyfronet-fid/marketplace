# frozen_string_literal: true

class Filter::ResearchActivity < Filter::AncestryMultiselect
  def initialize(params = {})
    super(
      params: params.fetch(:params, {}),
      field_name: "research_activities",
      title: "Research Activities",
      model: Vocabulary::ResearchActivity,
      joining_model: ServiceVocabulary,
      model_type: "Vocabulary::ResearchActivity",
      index: "research_activities",
      search: true
    )
  end
end
