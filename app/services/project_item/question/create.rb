# frozen_string_literal: true

class ProjectItem::Question::Create
  def initialize(question)
    @question = question
  end

  def call
    if @question.valid?
      project_item = @question.project_item
      history_entry = project_item.new_change(message: @question.text,
                                       author: @question.author)

      if history_entry&.persisted?
        ProjectItem::RegisterQuestionJob.perform_later(history_entry)
        true
      end
    end
  end
end
