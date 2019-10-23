# frozen_string_literal: true

class ResearchArea < ApplicationRecord
  include Parentable
  attr_accessor :move_ra_id

  has_many :service_research_areas, autosave: true, dependent: :destroy
  has_many :services, through: :service_research_areas
  has_many :project_research_areas, autosave: true, dependent: :destroy
  has_many :projects, through: :project_research_areas

  validates :name, presence: true, uniqueness: { scope: :ancestry }
  validate :parent_has_services, if: :parent

  def self.names
    all.map(&:name)
  end

  def self.leafs
    all_childless
  end

  def self.leafs_with_nested_names
    all_childless(true)
  end

  def self.other
    ResearchArea.find_by(name: "Other")
  end


  private

    def self.all_childless(with_names = false, records = ResearchArea.arrange, parent_name = "", result = [])
      records.each do |r, sub_r|
        if sub_r.blank?
          result << (with_names ? [name_with_path(parent_name, r.name), r] : r)
        else
          all_childless(with_names, sub_r, name_with_path(parent_name, r.name), result)
        end
      end
      result
    end

    def self.name_with_path(parent, child, separator = " ⇒ ")
      parent.blank? ? child : parent + separator + child
    end

    def parent_has_services
      errors.add(:parent_id, "has services") unless parent.services.blank?
    end
end
