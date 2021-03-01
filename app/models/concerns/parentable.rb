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
    begin
      if current.parent.present?
        object_array << current.parent unless current.parent.blank?
        current = current.parent
      end
      i += 1
    end while i < level_up && current.parent.present?
    method.present? ? object_array.map(&method.to_sym).join(separator) : object_array
  end

  module ClassMethods
    def child_names(records = self.arrange, parent_name = "", result = [])
      records.each do |r, sub_r|
        result << [name_with_path(parent_name, r.name), r]
        unless sub_r.blank?
          child_names(sub_r, name_with_path(parent_name, r.name), result)
        end
      end
      result
    end

    def name_with_path(parent, child, separator = " ⇒ ")
      parent.blank? ? child : parent + separator + child
    end
  end
end
