# frozen_string_literal: true

class ScientificDomain < ApplicationRecord
  include Parentable

  has_one_attached :logo

  has_many :service_scientific_domains, autosave: true, dependent: :destroy
  has_many :services, through: :service_scientific_domains
  has_many :project_scientific_domains, autosave: true, dependent: :destroy
  has_many :projects, through: :project_scientific_domains

  has_many :user_scientific_domains, autosave: true, dependent: :destroy
  has_many :users, through: :user_scientific_domains

  validates :name, presence: true, uniqueness: { scope: :ancestry }

  def self.names
    all.map(&:name)
  end

  def to_s
    self.name
  end


  private
    def self.child_names(records = ScientificDomain.arrange, parent_name = "", result = [])
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
