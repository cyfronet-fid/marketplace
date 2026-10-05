# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home page", type: :request do
  context "when the variant is marketplace" do
    before do
      allow(Mp::Variant).to receive(:marketplace?).and_return(true)
      get root_path
    end

    it "renders in the application layout" do
      expect(response).to render_template(layout: "layouts/application")
    end

    it "does not set the landing page action for the body class" do
      expect(assigns(:action)).not_to eq("landing_page")
    end
  end

  context "when the variant is pl or whitelabel" do
    before do
      allow(Mp::Variant).to receive(:marketplace?).and_return(false)
      get root_path
    end

    it "renders in the clear layout" do
      expect(response).to render_template(layout: "layouts/clear")
    end

    it "sets the landing page action for the body class" do
      expect(assigns(:action)).to eq("landing_page")
    end
  end
end
