# frozen_string_literal: true

module Offerable
  extend ActiveSupport::Concern

  included do
    enum order_type: {
        open_access: "open_access",
        fully_open_access: "fully_open_access",
        order_required: "order_required",
        other: "other"
    }

    validates :order_type, presence: true
    validates :name, presence: true
    validates :description, presence: true

    def external?
      order_required? && !effective_internal?
    end

    def orderable?
      order_required? && effective_internal?
    end

    private
      def effective_internal?
        internal || order_url.blank?
      end
  end
end
