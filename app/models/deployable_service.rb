# frozen_string_literal: true

class DeployableService < ApplicationRecord
  include Rails.application.routes.url_helpers
  include LogoAttachable
  include Publishable
  include Statusable
  include Viewable

  extend FriendlyId
  friendly_id :name, use: :slugged

  acts_as_taggable

  before_save { self.pid = upstream.eid if upstream_id.present? }

  has_one_attached :logo

  has_many :sources, class_name: "DeployableServiceSource", dependent: :destroy
  has_many :deployable_service_scientific_domains, dependent: :destroy
  has_many :scientific_domains, through: :deployable_service_scientific_domains

  belongs_to :upstream, foreign_key: "upstream_id", class_name: "DeployableServiceSource", optional: true
  belongs_to :resource_organisation, class_name: "Provider", optional: false
  belongs_to :catalogue, optional: true

  auto_strip_attributes :name, nullify: false
  auto_strip_attributes :description, nullify: false
  auto_strip_attributes :tagline, nullify: false
  auto_strip_attributes :url, nullify: false
  auto_strip_attributes :node, nullify: false
  auto_strip_attributes :version, nullify: false
  auto_strip_attributes :software_license, nullify: false

  validates :name, presence: true
  validates :description, presence: true
  validates :tagline, presence: true
  validates :url, mp_url: true, if: :url?
  validates :logo, blob: { content_type: :image }
  validate :logo_variable, on: %i[create update]

  accepts_nested_attributes_for :sources,
                                reject_if:
                                  lambda { |attributes| attributes["eid"].blank? || attributes["source_type"].blank? },
                                allow_destroy: true

  def to_param
    slug
  end

  private

  def logo_variable
    return unless logo.attached? && !logo.variable?

    errors.add(:logo, "Logo should be an image")
  end
end
