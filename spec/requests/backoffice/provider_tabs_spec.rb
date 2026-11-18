# frozen_string_literal: true

require "rails_helper"

# Each variant shows the eight tabs of the provider page. The fields of
# Provider::PlProfile show only under pl.
RSpec.describe "Backoffice: provider tabs", :backend do
  let(:coordinator) { create(:user, roles: [:coordinator]) }
  let(:provider) { create(:provider) }
  let(:tab_names) { response.body.scan(/provider-(\w+)-btn/).flatten }
  let(:turbo_stream) { { "Accept" => "text/vnd.turbo-stream.html, text/html" } }
  let(:network) { create(:network) }

  before { login_as(coordinator) }

  context "when running as marketplace" do
    before { allow(Mp::Variant).to receive_messages(marketplace?: true, pl?: false, whitelabel?: false) }

    describe "GET /backoffice/providers/:id" do
      before { get backoffice_provider_path(provider) }

      it "lists the eight tabs" do
        expect(tab_names).to eq(%w[profile classification location contacts maturity dependencies managers other])
      end
    end

    describe "GET /backoffice/providers/:id?tab=classification" do
      before { get backoffice_provider_path(provider, tab: "classification"), headers: turbo_stream }

      it "renders the scientific domains field" do
        expect(response.body).to include("provider[scientific_domain_ids][]")
      end
    end

    describe "GET /backoffice/providers/:id?tab=maturity" do
      before { get backoffice_provider_path(provider, tab: "maturity"), headers: turbo_stream }

      it "renders the life cycle status field" do
        expect(response.body).to include("provider[provider_life_cycle_status]")
      end

      it "hides the certifications of the pl profile" do
        expect(response.body).not_to include("provider[certifications]")
      end
    end

    describe "GET /backoffice/providers/:id?tab=dependencies" do
      before { get backoffice_provider_path(provider, tab: "dependencies"), headers: turbo_stream }

      it "renders the networks field" do
        expect(response.body).to include("provider[network_ids][]")
      end

      it "hides the affiliations of the pl profile" do
        expect(response.body).not_to include("provider[affiliations]")
      end
    end

    describe "GET /backoffice/providers/:id?tab=other" do
      before { get backoffice_provider_path(provider, tab: "other"), headers: turbo_stream }

      it "renders the ESFRI domains field" do
        expect(response.body).to include("provider[esfri_domain_ids][]")
      end

      it "hides the national roadmaps of the pl profile" do
        expect(response.body).not_to include("provider[national_roadmaps]")
      end
    end

    describe "PATCH /backoffice/providers/:id from the dependencies tab" do
      before do
        patch backoffice_provider_path(provider),
              params: {
                tab: "dependencies",
                provider: {
                  network_ids: [network.id]
                }
              },
              headers: turbo_stream
      end

      it "saves the networks" do
        expect(provider.reload.networks).to eq([network])
      end
    end
  end

  context "when running as whitelabel" do
    before { allow(Mp::Variant).to receive_messages(marketplace?: false, pl?: false, whitelabel?: true) }

    describe "GET /backoffice/providers/:id" do
      before { get backoffice_provider_path(provider) }

      it "lists the eight tabs" do
        expect(tab_names).to eq(%w[profile classification location contacts maturity dependencies managers other])
      end
    end

    describe "GET /backoffice/providers/:id?tab=classification" do
      before { get backoffice_provider_path(provider, tab: "classification"), headers: turbo_stream }

      it "renders the scientific domains field" do
        expect(response.body).to include("provider[scientific_domain_ids][]")
      end
    end

    describe "GET /backoffice/providers/:id?tab=maturity" do
      before { get backoffice_provider_path(provider, tab: "maturity"), headers: turbo_stream }

      it "renders the life cycle status field" do
        expect(response.body).to include("provider[provider_life_cycle_status]")
      end

      it "hides the certifications of the pl profile" do
        expect(response.body).not_to include("provider[certifications]")
      end
    end

    describe "GET /backoffice/providers/:id?tab=dependencies" do
      before { get backoffice_provider_path(provider, tab: "dependencies"), headers: turbo_stream }

      it "renders the networks field" do
        expect(response.body).to include("provider[network_ids][]")
      end

      it "hides the affiliations of the pl profile" do
        expect(response.body).not_to include("provider[affiliations]")
      end
    end

    describe "GET /backoffice/providers/:id?tab=other" do
      before { get backoffice_provider_path(provider, tab: "other"), headers: turbo_stream }

      it "renders the ESFRI domains field" do
        expect(response.body).to include("provider[esfri_domain_ids][]")
      end

      it "hides the national roadmaps of the pl profile" do
        expect(response.body).not_to include("provider[national_roadmaps]")
      end
    end

    describe "PATCH /backoffice/providers/:id from the dependencies tab" do
      before do
        patch backoffice_provider_path(provider),
              params: {
                tab: "dependencies",
                provider: {
                  network_ids: [network.id]
                }
              },
              headers: turbo_stream
      end

      it "saves the networks" do
        expect(provider.reload.networks).to eq([network])
      end
    end
  end

  context "when running as pl" do
    before { allow(Mp::Variant).to receive_messages(marketplace?: false, pl?: true, whitelabel?: false) }

    describe "GET /backoffice/providers/:id" do
      before { get backoffice_provider_path(provider) }

      it "lists the eight tabs" do
        expect(tab_names).to eq(%w[profile classification location contacts maturity dependencies managers other])
      end
    end

    describe "GET /backoffice/providers/:id?tab=maturity" do
      before { get backoffice_provider_path(provider, tab: "maturity"), headers: turbo_stream }

      it "renders the certifications of the pl profile" do
        expect(response.body).to include("provider[certifications]")
      end
    end

    describe "GET /backoffice/providers/:id?tab=dependencies" do
      before { get backoffice_provider_path(provider, tab: "dependencies"), headers: turbo_stream }

      it "renders the affiliations of the pl profile" do
        expect(response.body).to include("provider[affiliations]")
      end
    end

    describe "GET /backoffice/providers/:id?tab=other" do
      before { get backoffice_provider_path(provider, tab: "other"), headers: turbo_stream }

      it "renders the national roadmaps of the pl profile" do
        expect(response.body).to include("provider[national_roadmaps]")
      end
    end
  end
end
