# frozen_string_literal: true

require "rails_helper"

class MyFilter < Filter
  def initialize(params = {})
    super(params: params.fetch(:params, {}), field_name: "my_filter", type: :select, title: "My Filter", index: "test")
  end

  protected

  def fetch_options
    if @my_options
      raise "boom! fetching options for the second time"
    else
      @my_options = [{ name: "A", id: "1", count: 1 }, { name: "B", id: "2", count: 2 }]
    end
  end

  def where_constraint
    { key: :value }
  end
end

RSpec.describe Filter, backend: true do
  context "#options" do
    it "returns filter select options" do
      filter = MyFilter.new

      expect(filter.options).to contain_exactly({ name: "A", id: "1", count: 1 }, { name: "B", id: "2", count: 2 })
    end

    it "are cached" do
      filter = MyFilter.new

      filter.options
      filter.options
    end
  end

  context "#constraints" do
    it "is invoked when filter is active" do
      filter = MyFilter.new(params: { "my_filter" => "s2" })

      expect(filter.constraint).to eq(key: :value)
    end

    it "returns all records when filter is not active" do
      filter = MyFilter.new

      expect(filter.constraint).to eq({})
    end
  end

  context "#active_filters" do
    it "returns list of active filters when params are a list" do
      params = ActionController::Parameters.new("my_filter" => %w[1 2])
      filter = MyFilter.new(params: params)

      expect(filter.active_filters).to contain_exactly(["My Filter", "A", anything], ["My Filter", "B", anything])
    end

    it "returns one active filter when param is a value" do
      params = ActionController::Parameters.new("my_filter" => "1")
      filter = MyFilter.new(params: params)

      expect(filter.active_filters).to contain_exactly(["My Filter", "A", anything])
    end

    it "ignores non existing filter values" do
      params = ActionController::Parameters.new("my_filter" => "non-existing")
      filter = MyFilter.new(params: params)

      expect(filter.active_filters).to contain_exactly(["My Filter", nil, {}])
    end

    it "removes itself from params list" do
      params = ActionController::Parameters.new("my_filter" => "1", "a" => "b")
      filter = MyFilter.new(params: params)

      expect(filter.active_filters).to contain_exactly(["My Filter", "A", "a" => "b"])
    end
  end
end
