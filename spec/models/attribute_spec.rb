# frozen_string_literal: true

require "rails_helper"

RSpec.describe Attribute do

  it 'does anything', focus: true do
    attr = Attribute.from_json({
                                   "id"=> "id1",
                                   "label"=> "Attribute 1",
                                   "type"=> "select",
                                   "value_type"=> "string",
                                   "value"=> "b",
                                   "config"=> {
                                       "values"=> ["a", "b", "c"]
                                   }
                               })
    expect(attr.config_valid?).to be true
    expect(attr.value_valid?).to be true
  end

  it 'sets value from param', focus: true do
    attr = Attribute.from_json({
                                   "id"=> "id1",
                                   "label"=> "Attribute 1",
                                   "type"=> "select",
                                   "value_type"=> "string",
                                   "config"=> {
                                       "values"=> ["a", "b", "c"]
                                   }
                               })
    attr.value_from_param(["a"])
  end

  it 'does anything', focus: true do
    attr = Attribute.from_json({
                                   "id"=> "id1",
                                   "label"=> "Attribute 1",
                                   "type"=> "attribute",
                                   "value_type"=> "string",
                                   "value"=> "b",
                               })
    expect(attr.value_valid?).to be true
    puts attr.to_json
  end

  it 'fails on wrong value type', focus: true do
    attr = Attribute.from_json({
                                   "id"=> "id1",
                                   "label"=> "Attribute 1",
                                   "type"=> "attribute",
                                   "value_type"=> "integer",
                                   "value"=> 1,
                               })
    expect(attr.value_valid?).to be true
    puts attr.to_json
  end

  it 'date property', focus: true do
    attr = Attribute.from_json({
                                   "id"=> "id1",
                                   "label"=> "Attribute 1",
                                   "type"=> "date",
                                   "value_type"=> "string",
                                   "value"=> "10/23/2018",
                               })
    puts attr.to_json
    expect(attr.value_valid?).to be true
    puts attr.to_json
  end

  it 'fails on invalid attribute type', focus: true do
    expect {
      Attribute.from_json({
                                   "id"=> "id1",
                                   "label"=> "Attribute 1",
                                   "type"=> "select",
                                   "value_type"=> "fail",
                                   "value"=> "b",
                                   "config"=> {
                                       "values"=> ["a", "b", "c"]
                                   }
                               })
    }.to raise_exception(JSON::Schema::ValidationError)
  end

  it 'does anything', focus: true do
    attr = Attribute.from_json({
                                   "id"=> "id1",
                                   "label"=> "Attribute 1",
                                   "type"=> "select",
                                   "value_type"=> "integer",
                                   "value"=> 1,
                                   "config"=> {
                                       "values"=> [1, 2, 3]
                                   }
                               })
    expect(attr.config_valid?).to be true
    expect(attr.value_valid?).to be true
    puts attr.to_json
  end

  it 'does anything', focus: true do
    attr = Attribute.from_json({
                                   "id"=> "id1",
                                   "label"=> "Attribute 1",
                                   "type"=> "multiselect",
                                   "value_type"=> "integer",
                                   "value"=> [1, 2, 3],
                                   "config"=> {
                                       "values"=> [1, 2, 3]
                                   }
                               })
    expect(attr.config_valid?).to be true
    expect(attr.value_valid?).to be true
    puts attr.to_json
  end

  it 'does anything', focus: true do
    attr = Attribute.from_json({
                                   "id"=> "id1",
                                   "label"=> "Attribute 1",
                                   "type"=> "multiselect",
                                   "value_type"=> "string",
                                   "value"=> ["1", "2"],
                                   "config"=> {
                                       "values"=> ["1", "2", "3"]
                                   }
                               })
    expect(attr.config_valid?).to be true
    expect(attr.value_valid?).to be true
    puts attr.to_json
  end

  it 'creates range property', focus: true do
    attr = Attribute.from_json({
                                   "id"=> "id1",
                                   "label"=> "Attribute 1",
                                   "type"=> "range-property",
                                   "value_type"=> "string",
                                   "value"=> {
                                       "minimum"=> "1312",
                                       "maximum"=> "312312"
                                   }
                               })
    expect(attr.value_valid?).to be true
    puts attr.to_json
  end


  it 'creates number range', focus: true do
    attr = Attribute.from_json({
                                   "id"=> "id1",
                                   "label"=> "Attribute 1",
                                   "type"=> "range",
                                   "value_type"=> "integer",
                                   "value"=> 1,
                                   "config"=> {
                                       "minimum"=> 1,
                                       "maximum"=> 100,
                                   }
                               })
    expect(attr.value_valid?).to be true
    puts attr.to_json
  end

  it 'creates invalid number range', focus: true do
    attr = Attribute.from_json({
                                   "id"=> "id1",
                                   "label"=> "Attribute 1",
                                   "type"=> "range",
                                   "value_type"=> "number",
                                   "value"=> 0,
                                   "config"=> {
                                       "minimum"=> 1,
                                       "maximum"=> 100,
                                       "exclusiveMinimum"=>true
                                   }
                               })
    expect(attr.value_valid?).to be false
    puts attr.to_json
  end

  it 'does anything', focus: true do
    expect{ Attribute.from_json({"id"=> "id1"} ) }.to raise_exception(JSON::Schema::ValidationError)
  end

end


