# frozen_string_literal: true

class Filter::Tag < Filter
  def initialize(params = {})
    super(params: params.fetch(:params, {}), field_name: "tag", type: :select, title: "Tags", index: "tags")
  end

  def visible?
    false
  end

  private

  def fetch_options
    ActsAsTaggableOn::Tag.all.map { |t| { name: t.name, id: t.name.downcase } }.sort { |x, y| x[:name] <=> y[:name] }
  end

  def where_constraint
    { @index.to_sym => values&.map(&:downcase) }
  end
end
