# frozen_string_literal: true

class ResearchArea < ApplicationRecord
  include Parentable

  has_many :service_research_areas, autosave: true, dependent: :destroy
  has_many :services, through: :service_research_areas
  has_many :project_research_areas, autosave: true, dependent: :destroy
  has_many :projects, through: :project_research_areas

  validates :name, presence: true, uniqueness: { scope: :ancestry }

  def self.names
    all.map(&:name)
  end


  private

    def self.child_names(records = ResearchArea.arrange, parent_name = "", result = [])
      records.each do |r, sub_r|
        result << [name_with_path(parent_name, r.name), r]
        unless sub_r.blank?
          child_names(sub_r, name_with_path(parent_name, r.name), result)
        end
      end
      result
    end

    def self.name_with_path(parent, child, separator = " ⇒ ")
      parent.blank? ? child : parent + separator + child
    end
end
