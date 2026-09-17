# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Publish, :backend do
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

  context "when the service cannot be updated" do
    subject(:publish) { described_class.call(service) }

    let(:service) { create(:service, status: :draft) }
    let!(:offer) { create(:offer, service: service, status: :draft) }

    before do
      allow(service).to receive(:update).and_return(false)
      allow(Service::Mailer::SendToSubscribers).to receive(:new).and_call_original
      publish
    end

    it "returns false" do
      expect(publish).to be false
    end

    it "leaves the single offer unpublished" do
      expect(offer.reload).to be_draft
    end

    it "does not notify subscribers" do
      expect(Service::Mailer::SendToSubscribers).not_to have_received(:new)
    end
  end

  describe "#bundled_offers" do
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
