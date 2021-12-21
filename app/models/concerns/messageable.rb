# frozen_string_literal: true

module Messageable
  extend ActiveSupport::Concern

  included do
    has_many :messages, as: :messageable, dependent: :destroy
    before_create :set_conversation_last_seen

    def new_messages_to_user
      messages.where(
        "created_at > ? AND scope != ? AND author_role IN (?)",
        conversation_last_seen,
        "internal",
        %w[provider mediator]
      )
    end

    def user_has_new_messages?
      new_messages_to_user.present?
    end

    def earliest_new_message_to_user
      new_messages_to_user.order(:created_at).first
    end

    private

    def set_conversation_last_seen
      self.conversation_last_seen = created_at
    end
  end
end
