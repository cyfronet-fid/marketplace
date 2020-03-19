# frozen_string_literal: true

class Offer < ApplicationRecord
  include Offerable

  STATUSES = {
    published: "published",
    draft: "draft"
  }

  enum status: STATUSES

  before_save :convert_parameters_to_json

  belongs_to :service

  counter_culture :service, column_name: proc { |model| model.published? ? "offers_count" : nil },
                  column_names: {
                      ["offers.status = ?", "published"] => "offers_count"
                  }

  has_many :project_items,
           dependent: :restrict_with_error

  validate :set_iid, on: :create
  validates :service, presence: true
  validates :iid, presence: true, numericality: true
  validates :status, presence: true
  validate :parameters_are_valid_attributes, on: [:create, :update]
  validates :parameters_as_string, attribute_id_unique: true
  validate :parameters_not_nil
  validates :webpage, presence: true, mp_url: true, unless: :orderable?

  attr_writer :parameters_as_string
  validates_associated :parameters

  def to_param
    iid.to_s
  end

  def attributes
    (parameters || []).map { |param| Attribute.from_json(param) }
  end

  def parameters
    @parameters || []
  end

  def parameters_attributes=(attrs)
    @parameters = attrs.map { |i, params| AttributeTemplate.build(params) }.reject(&:blank?)
  end

  def open_access?
    offer_type == "open_access"
  end

  def orderable?
    offer_type == "orderable"
  end

  def external?
    offer_type == "external"
  end

  def parameters_as_string?
    @parameters_as_string.present?
  end

  def parameters_as_string
    if !@parameters_as_string && !parameters.nil?
      @parameters_as_string = parameters.map(&:to_json)
    end
    @parameters_as_string
  end

  private
    def parameters_are_valid_attributes
      (parameters_as_string || []).each_with_index.map do |param, i|
        param = JSON.parse(param)
        attribute = Attribute.from_json(param)
        attribute.validate_config!
      rescue JSON::ParserError
        errors.add("parameters_as_string_#{i}", "Cannot convert parameters to json")
      rescue JSON::Schema::ValidationError => e
        errors.add("parameters_as_string_#{i}", e.message)
      end
    end

    def convert_parameters_to_json
      unless parameters_as_string.nil?
        self.parameters = parameters_as_string.map { |p| JSON.parse(p) }
      end
    end

    def set_iid
      self.iid = offers_count + 1 if iid.blank?
    end

    def offers_count
      service && service.offers.maximum(:iid).to_i || 0
    end

    def parameters_not_nil
      if self.parameters.nil?
        errors.add :parameters, "cannot be nil"
      end
    end
end
