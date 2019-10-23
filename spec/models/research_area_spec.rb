# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResearchArea, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }

    subject { create(:research_area) }
    it { should validate_uniqueness_of(:name).scoped_to(:ancestry) }

    it "should return validation error if we try to create research area with parent contains services" do
      parent = create(:research_area)
      create_list(:service, 3, research_areas: [parent])
      child = build(:research_area, parent: parent)
      expect { child.save! }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Parent has services")
    end
  end

  describe "#potential_parents" do
    it "includes potential parents" do
      research_area = create(:research_area)
      other = create(:research_area)

      expect(research_area.potential_parents).to eq([other])
    end

    it "returns all existing research areas for new record" do
      research_area = ResearchArea.new
      other = create(:research_area)

      expect(research_area.potential_parents).to eq([other])
    end

    it "does not include itself" do
      research_area = create(:research_area)

      expect(research_area.potential_parents).to eq([])
    end

    it "does not include children" do
      research_area = create(:research_area)
      child = create(:research_area, parent: research_area)
      create(:research_area, parent: child)

      expect(research_area.potential_parents).to eq([])
    end
  end
end
