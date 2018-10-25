# frozen_string_literal: true

class Offer < ApplicationRecord
  belongs_to :service,
             counter_cache: true

  has_many :project_items,
           dependent: :restrict_with_error

  validate :set_iid, on: :create
  validates :name, presence: true
  validates :description, presence: true
  validates :service, presence: true
  validates :iid, presence: true, numericality: true

  def to_param
    iid.to_s
  end

  def attributes
    [Attribute.from_json({
                             "id"=> "id1",
                             "label"=> "Weight of your biggest animal",
                             "description"=> "Description 1",
                             "type"=> "multiselect",
                             "value_type"=> "string",
                             "unit" => "kg",
                             "config"=> {
                                 "values"=> ["100", "200", "300"],
                                 "minItems"=> 1
                             }
                         }),
     Attribute.from_json({
                             "id"=> "id2",
                             "label"=> "Your favourite memory size",
                             "description"=> "Description 2",
                             "type"=> "select",
                             "value_type"=> "integer",
                             "unit"=>"GB",
                             "config"=> {
                                 "mode"=> "buttons",
                                 "values"=> [1, 2, 3]
                             }
                         }),
     Attribute.from_json({
                             "id"=> "id3",
                             "label"=> "Best movie of all time",
                             "description"=> "Description 3",
                             "type"=> "select",
                             "value_type"=> "string",
                             "config"=> {
                                 "mode"=> "dropdown",
                                 "values"=> ["Titanic", "Batman", "Matrix"]
                             }
                         }),
     Attribute.from_json({
                             "id"=> "id4",
                             "label"=> "How many kids you have",
                             "description"=> "Description 4",
                             "type"=> "input",
                             "value_type"=> "integer"
                         }),
     Attribute.from_json({
                             "id"=> "id5",
                             "label"=> "Make a comment",
                             "description"=> "Description 5",
                             "type"=> "input",
                             "value_type"=> "string"
                         }),
     Attribute.from_json({
                             "id"=> "id6",
                             "label"=> "Some important date",
                             "description"=> "Description 6",
                             "type"=> "date",
                             "value_type"=> "string"
                         })]
  end

  private

  def set_iid
    self.iid = offers_count + 1 if iid.blank?
  end

  def offers_count
    service && service.offers.maximum(:iid).to_i || 0
  end
end
