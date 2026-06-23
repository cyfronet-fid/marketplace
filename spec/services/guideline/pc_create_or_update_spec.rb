# frozen_string_literal: true

require "rails_helper"

describe Guideline::PcCreateOrUpdate, backend: true do
  it "creates an active guideline from V6 name" do
    guideline_data = { "id" => "guideline-v6", "name" => "V6 interoperability guideline" }

    expect { described_class.new(guideline_data, :published, Time.current).call }.to change(Guideline, :count).by(1)
    expect(Guideline.last).to have_attributes(eid: "guideline-v6", title: "V6 interoperability guideline")
  end

  it "updates an existing guideline from V6 name" do
    guideline = Guideline.create!(eid: "guideline-v6", title: "Old title")
    guideline_data = { "id" => "guideline-v6", "name" => "Updated V6 interoperability guideline" }

    described_class.new(guideline_data, :published, Time.current).call

    expect(guideline.reload.title).to eq("Updated V6 interoperability guideline")
  end

  it "falls back to legacy title" do
    guideline_data = { "id" => "guideline-v5", "title" => "Legacy guideline title" }

    expect { described_class.new(guideline_data, :published, Time.current).call }.to change(Guideline, :count).by(1)
    expect(Guideline.last).to have_attributes(eid: "guideline-v5", title: "Legacy guideline title")
  end
end
