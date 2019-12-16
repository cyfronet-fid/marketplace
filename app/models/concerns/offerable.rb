# frozen_string_literal: true

module Offerable
  extend ActiveSupport::Concern

  included do
    enum offer_type: {
      orderable: "orderable",
      open_access: "open_access",
      external: "external"
    }

    validates :offer_type, presence: true
    validates :name, presence: true
    validates :description, presence: true
  end
end
