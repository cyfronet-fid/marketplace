# frozen_string_literal: true

require "rails_helper"

RSpec.describe Filter::Tag do
  context "#options" do
    it "returns all services tags" do
      create(:service, tag_list: ["tag1", "tag2"])
      create(:service, tag_list: ["tag3"])
      filter = described_class.new

      expect(filter.options).to contain_exactly(["tag1", "tag1"],
                                                ["tag2", "tag2"],
                                                ["tag3", "tag3"])
    end
  end

  context "call" do
    it "filters services basing on selected tag" do
      service = create(:service, tag_list: ["foo bar"])
      _other_service = create(:service)
      filter = described_class.new(params: { "tag" => "foo bar" })

      expect(filter.call(Service.all)).to contain_exactly(service)
    end
  end
end
