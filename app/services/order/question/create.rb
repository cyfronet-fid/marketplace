# frozen_string_literal: true

class Order::Question::Create
  def initialize(question)
    @question = question
  end

  def call
    if @question.valid?
      order = @question.order
      history_entry = order.new_change(message: @question.text,
                                       author: @question.author)

      if history_entry&.persisted?
        Order::RegisterQuestionJob.perform_later(history_entry)
        true
      end
    end
  end
end
