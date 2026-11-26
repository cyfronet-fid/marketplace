# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statistics::PageParams, :backend do
  it "takes the defaults for a query without values or with blank ones" do
    queries = [{}, { from_id: "", limit: "" }].map { |query| ActionController::Parameters.new(query) }

    expect(queries.map { |query| described_class.from_query(query) }).to all(
      be_valid.and(have_attributes(from_id: 0, limit: 100, pids: nil))
    )
  end

  it "reads from_id and limit of the query as integers and pid[] as the PIDs" do
    query = ActionController::Parameters.new(from_id: "12", limit: "1000", pid: %w[21.T15999/a 21.T15999/b])

    expect(described_class.from_query(query)).to be_valid
      .and have_attributes(from_id: 12, limit: 1000, pids: %w[21.T15999/a 21.T15999/b])
  end

  it "keeps an empty pid[], which matches no Service" do
    expect(described_class.from_query(ActionController::Parameters.new(pid: []))).to have_attributes(pids: [])
  end

  {
    { from_id: "-1" } => "'from_id' must be a non-negative integer",
    { from_id: "abc" } => "'from_id' must be a non-negative integer",
    { from_id: "5abc" } => "'from_id' must be a non-negative integer",
    { from_id: ["1"] } => "'from_id' must be a non-negative integer",
    { limit: "0" } => "'limit' must be an integer from 1 to 1000",
    { limit: "1001" } => "'limit' must be an integer from 1 to 1000",
    { limit: "5abc" } => "'limit' must be an integer from 1 to 1000",
    { limit: "1.5" } => "'limit' must be an integer from 1 to 1000",
    { limit: ["1"] } => "'limit' must be an integer from 1 to 1000",
    { pids: "21.T15999/a" } => "'pid' must be a list of PIDs: pid[]=…&pid[]=…",
    { pids: { "a" => "21.T15999/a" } } => "'pid' must be a list of PIDs: pid[]=…&pid[]=…",
    { pids: ["a" => "21.T15999/a"] } => "'pid' must be a list of PIDs: pid[]=…&pid[]=…",
    { pids: Array.new(101) { |n| "21.T15999/#{n}" } } => "'pid' must hold at most 100 PIDs"
  }.each do |attributes, message|
    it "refuses #{attributes.keys.sole} #{attributes.values.sole.inspect.truncate(30)}" do
      page_params = described_class.new(**attributes)

      expect(page_params.tap(&:validate).errors.map(&:message)).to eq([message])
    end
  end

  it "accepts 100 PIDs" do
    expect(described_class.new(pids: Array.new(100) { |n| "21.T15999/#{n}" })).to be_valid
  end

  it "tells every value that isn't valid" do
    page_params = described_class.new(from_id: "-1", limit: "0", pids: "21.T15999/a").tap(&:validate)

    expect(page_params.errors.attribute_names).to eq(%i[from_id limit pids])
  end
end
