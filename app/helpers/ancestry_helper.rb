# frozen_string_literal: true

module AncestryHelper
  def ancestry_tree(records)
    first = records.first
    first ? create_ancestry_tree(records, first.class.new, 0) : []
  end

  def ancestry_id_tree(records)
    ancestry_tree(records).map { |r| [r.first, r.last.id] }
  end

  private

  def create_ancestry_tree(records, parent, level)
    records
      .select { |r| r.ancestry_depth == level && r.child_of?(parent) }
      .flat_map { |r| [[indented_name(r.name, level), r], *create_ancestry_tree(records, r, level + 1)] }
  end

  def indented_name(name, level)
    indentation = "&nbsp;&nbsp;" * level
    "#{indentation}#{ERB::Util.html_escape(name)}".html_safe
  end
end
