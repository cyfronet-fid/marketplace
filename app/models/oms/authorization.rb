# frozen_string_literal: true

class OMS::Authorization < ApplicationRecord
  belongs_to :trigger, foreign_key: :oms_trigger_id
end
