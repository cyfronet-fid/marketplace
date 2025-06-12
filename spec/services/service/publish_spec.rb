# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Publish, backend: true do
  context "publish" do
    it "publish service" do
      service = create(:service)

      described_class.call(service)

      expect(service.reload).to be_published
    end

    it "sends email to interested users" do
      user = create(:user_with_interests)
      service = create(:service, scientific_domains: user.scientific_domains, categories: user.categories)

      expect { described_class.call(service) }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it "sends email only to interested users" do
      users = create_list(:user_with_interests, 3)
      common_scientific_domains = users.first.scientific_domains + users.second.scientific_domains
      common_categories = users.first.categories + users.second.categories
      service = create(:service, scientific_domains: common_scientific_domains, categories: common_categories)
      expect { described_class.call(service) }.to change { ActionMailer::Base.deliveries.count }.by(2)
      expect(ActionMailer::Base.deliveries.last(2).first.to).to contain_exactly(users.first.email)
      expect(ActionMailer::Base.deliveries.last.to).to contain_exactly(users.second.email)
    end
  end

  context "#bundled_offers" do
    it "doesn't send notification if service wasn't made public" do
      service = build(:service, status: "errored")
      create(:offer, service: service)
      create(:bundle, service: service, offers: [build(:offer)])
      expect { described_class.call(service) }.not_to change { ActionMailer::Base.deliveries.count }
    end

    it "sends notification if service made public" do
      service = create(:service, status: "draft")
      create(:offer, service: service)
      create(:bundle, service: service)
      expect { described_class.call(service) }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end
end
