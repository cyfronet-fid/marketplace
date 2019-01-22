# frozen_string_literal: true

module Parentable
  extend ActiveSupport::Concern

  included do
    has_ancestry cache_depth: true
  end

  def potential_parents
    persisted? ? self.class.where.not(id: descendant_ids + [id]) : self.class.all
  end
end
