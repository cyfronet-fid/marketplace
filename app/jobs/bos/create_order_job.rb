# frozen_string_literal: true

class Bos::CreateOrderJob < ApplicationJob
  include BosRetryable

  def perform(project_item)
    Bos::Client.new.create_order(project_item)
  end
end
