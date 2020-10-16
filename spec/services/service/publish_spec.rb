# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Publish do
  context "publish" do
    it "publish service" do
      service = create(:service)

      described_class.new(service).call

      expect(service.reload).to be_published
    end

    it "sends email to interested users" do
      user = create(:user_with_interests)
      service = create(:service, scientific_domains: user.scientific_domains, categories: user.categories)

      expect { described_class.new(service).call }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it "sends email only to interested users" do
      users = create_list(:user_with_interests, 3)
      common_scientific_domains = users.first.scientific_domains + users.second.scientific_domains
      common_categories = users.first.categories + users.second.categories
      service = create(:service, scientific_domains: common_scientific_domains, categories: common_categories)
      expect { described_class.new(service).call }.to change { ActionMailer::Base.deliveries.count }.by(2)
      expect(ActionMailer::Base.deliveries.last(2).first.to).to contain_exactly(users.first.email)
      expect(ActionMailer::Base.deliveries.last.to).to contain_exactly(users.second.email)
    end
  end

  it "publish unverified service" do
    service = create(:service)

    described_class.new(service, verified: false).call

    expect(service.reload).to be_unverified
  end
end
