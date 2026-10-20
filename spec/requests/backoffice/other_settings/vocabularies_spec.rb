# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Backoffice: manage a vocabulary", :backend do
  let(:coordinator) { create(:user, roles: [:coordinator]) }

  before { login_as(coordinator) }

  describe "a vocabulary whose route differs from its model name" do
    # VOCABULARY_TYPES is built at boot, so the pl-only type exists only when the suite runs as pl.
    before { skip "the product access policy vocabulary exists under pl only" unless Mp::Variant.pl? }

    context "when rendering the new form" do
      before { get "/backoffice/other_settings/vocabularies/product_access_policies/new" }

      it "posts to the route of the type" do
        expect(response.body).to include('action="/backoffice/other_settings/vocabularies/product_access_policies"')
      end
    end

    context "when creating it" do
      before do
        post "/backoffice/other_settings/vocabularies/product_access_policies",
             params: { vocabulary_research_product_access_policy: { name: "Open", eid: "rp_access_policy-open" } }
      end

      it "creates the vocabulary" do
        expect(Vocabulary::ResearchProductAccessPolicy.where(name: "Open")).to exist
      end

      it "redirects to the created vocabulary" do
        created = Vocabulary::ResearchProductAccessPolicy.find_by!(name: "Open")
        expect(response).to redirect_to("/backoffice/other_settings/vocabularies/product_access_policies/#{created.id}")
      end
    end

    context "when updating it" do
      let(:vocabulary) do
        Vocabulary::ResearchProductAccessPolicy.create!(name: "Open", eid: "rp_access_policy-open")
      end

      before do
        patch "/backoffice/other_settings/vocabularies/product_access_policies/#{vocabulary.id}",
              params: { vocabulary_research_product_access_policy: { name: "Restricted" } }
      end

      it "renames the vocabulary" do
        expect(vocabulary.reload.name).to eq("Restricted")
      end

      it "redirects to the vocabulary" do
        expect(response).to redirect_to(
          "/backoffice/other_settings/vocabularies/product_access_policies/#{vocabulary.id}"
        )
      end
    end
  end

  describe "a vocabulary of every variant" do
    let(:trl) { create(:trl, name: "TRL 1") }

    before { patch backoffice_other_settings_trl_path(trl), params: { vocabulary_trl: { name: "TRL 2" } } }

    it "renames the vocabulary" do
      expect(trl.reload.name).to eq("TRL 2")
    end

    it "redirects to the vocabulary" do
      expect(response).to redirect_to(backoffice_other_settings_trl_path(trl))
    end
  end
end
