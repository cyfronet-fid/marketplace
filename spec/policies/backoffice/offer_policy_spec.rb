# frozen_string_literal: true

require "rails_helper"

GRANTED_USERS = %i[coordinator owner].freeze
USERS = (GRANTED_USERS + %i[stranger]).freeze

RSpec.describe Backoffice::OfferPolicy, backend: true do
  let(:coordinator) { create(:user, roles: [:coordinator]) }
  let(:owner) { create(:user) }
  let(:stranger) { create(:user) }
  let(:provider) { create(:provider, data_administrators: [build(:data_administrator, email: owner.email)]) }
  let(:service) { create(:service, resource_organisation: provider) }

  subject { described_class }

  shared_examples "basic_test" do
    USERS.each do |user|
      granted = user.in? GRANTED_USERS
      it "#{granted ? "grants" : "denies"} access to #{user}" do
        expect(subject).to permit(send(user), offer) if granted
        expect(subject).to_not permit(send(user), offer) unless granted
      end
    end
  end

  shared_examples "deny_test" do
    USERS.each do |user|
      it "danies access to #{user}" do
        expect(subject).to_not permit(send(user), offer)
      end
    end
  end

  permissions :new? do
    let(:offer) { build(:offer, service: service) }
    it_behaves_like "basic_test"
  end

  permissions :destroy? do
    let(:offer) { create(:offer, service: service) }

    context "service is ordered using this offer" do
      before { create(:project_item, offer: offer) }
      it_behaves_like "deny_test"
    end
  end

  context "when offer is published" do
    let(:offer) { build(:offer, service: service, status: :published) }

    permissions :create?, :edit?, :update? do
      it_behaves_like "basic_test"
    end

    permissions :destroy? do
      context "not persisted offer" do
        it_behaves_like "deny_test"
      end

      context "persisted offer if there is only one" do
        before { offer.save }
        it_behaves_like "deny_test"
      end

      context "many offers" do
        before do
          offer.save
          create(:offer, service: offer.service)
        end
        it_behaves_like "basic_test"
      end
    end
  end

  context "when offer is a draft" do
    let(:offer) { build(:offer, service: service, status: :draft) }

    permissions :create?, :edit?, :update? do
      it_behaves_like "basic_test"
    end
  end

  context "When offer is published and service is deleted" do
    let(:service) { create(:service, resource_organisation: provider, status: :deleted) }
    let(:offer) { build(:offer, service: service, status: :published) }

    permissions :create?, :edit?, :update?, :destroy? do
      it_behaves_like "deny_test"
    end
  end

  context "When offer is draft and service is deleted" do
    let(:service) { create(:service, resource_organisation: provider, status: :deleted) }
    let(:offer) { build(:offer, service: service, status: :draft) }

    permissions :create?, :edit?, :update?, :destroy? do
      it_behaves_like "deny_test"
    end
  end
end
