# frozen_string_literal: true

module Parentable
  extend ActiveSupport::Concern

  included do
    has_ancestry cache_depth: true
  end

  def potential_parents
    persisted? ? self.class.where.not(id: descendant_ids + [id]) : self.class.all
  end

  def name_with_parent(method: "name", separator: ": ", level_up: 1)
    object_array = [self]
    i = 0
    current = self
    loop do
      if current.parent.present?
        object_array << current.parent if current.parent.present?
        current = current.parent
      end
      i += 1
      break unless i < level_up && current.parent.present?
    end
    method.present? ? object_array.map(&method.to_sym).join(separator) : object_array
  end

  module ClassMethods
    def child_names(records = arrange, parent_name = "", result = [])
      records.each do |r, sub_r|
        result << [name_with_path(parent_name, r.name), r]
        child_names(sub_r, name_with_path(parent_name, r.name), result) if sub_r.present?
      end
      result
    end

    def name_with_path(parent, child, separator = " ⇒ ")
      parent.blank? ? child : parent + separator + child
    end
  end
end
