# frozen_string_literal: true

class TourFeedback < ApplicationRecord
  belongs_to :user, optional: true
end
