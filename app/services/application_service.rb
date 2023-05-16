# frozen_string_literal: true

class ApplicationService
  def self.call(...)
    new(...).call
  end

  def call
    raise "Should be implemented in descendent class"
  end

  def hierarchical_to_s(hierarchical)
    result = []
    result.push(hierarchical.ancestors.to_a.append(hierarchical).map(&:name).join(">"))
    hierarchical.ancestors.to_a.map do |ancestor|
      result.push(ancestor.ancestors.to_a.append(ancestor).map(&:name).join(">"))
    end
    result
  end
end
